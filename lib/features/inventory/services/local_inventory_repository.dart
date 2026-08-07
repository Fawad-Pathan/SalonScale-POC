import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../inventory/models/inventory_record.dart';
import '../../scanning/models/inventory_scan.dart';
import '../../scanning/models/scan_product_result.dart';
import 'inventory_repository.dart';

class LocalInventoryRepository implements InventoryRepository {
  LocalInventoryRepository(this.preferences) {
    _emitCurrentState();
  }

  final SharedPreferences preferences;

  static const _scansKey = 'salonscale_scans';
  static const _inventoryKey = 'salonscale_inventory';

  final _scanController = StreamController<List<InventoryScan>>.broadcast();
  final _inventoryController =
      StreamController<List<InventoryRecord>>.broadcast();

  @override
  Stream<List<InventoryScan>> watchScans(String salonId) async* {
    yield _loadScans(salonId);
    yield* _scanController.stream.map(
        (scans) => scans.where((scan) => scan.salonId == salonId).toList());
  }

  @override
  Stream<List<InventoryRecord>> watchInventory(String salonId) async* {
    yield _loadInventory(salonId);
    yield* _inventoryController.stream.map((_) => _loadInventory(salonId));
  }

  @override
  Future<List<InventoryScan>> getScans(String salonId) async =>
      _loadScans(salonId);

  @override
  Future<List<InventoryRecord>> getInventory(String salonId) async =>
      _loadInventory(salonId);

  @override
  Future<InventoryScan?> getScan(
      {required String salonId, required String scanId}) async {
    for (final scan in _loadScans(salonId)) {
      if (scan.id == scanId) {
        return scan;
      }
    }
    return null;
  }

  @override
  Future<void> saveScan(InventoryScan scan, {File? image}) async {
    final scans = _loadScans(scan.salonId);
    final withoutExisting =
        scans.where((existing) => existing.id != scan.id).toList();
    final stored = [
      scan,
      ...withoutExisting,
    ]..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    await preferences.setString(
        _scansKey, jsonEncode(stored.map((item) => item.toJson()).toList()));
    await _saveInventory(scan.salonId, _recordsFromScan(scan));
    _emitCurrentState();
  }

  @override
  Future<void> deleteScan(
      {required String salonId, required String scanId}) async {
    final remaining = _loadScans(salonId)
        .where((scan) => scan.id != scanId)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    await preferences.setString(
        _scansKey, jsonEncode(remaining.map((item) => item.toJson()).toList()));
    final latestRecords = remaining.isEmpty
        ? <InventoryRecord>[]
        : _recordsFromScan(remaining.first);
    await _replaceInventory(salonId, latestRecords);
    _emitCurrentState();
  }

  Future<void> clear() async {
    await preferences.remove(_scansKey);
    await preferences.remove(_inventoryKey);
    _emitCurrentState();
  }

  List<InventoryScan> _loadScans(String salonId) {
    final raw = preferences.getString(_scansKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map((item) => InventoryScan.fromJson(Map<String, dynamic>.from(item)))
        .where((scan) => scan.salonId == salonId)
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  List<InventoryRecord> _loadInventory(String salonId) {
    final raw = preferences.getString(_inventoryKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const [];
    }
    final records = decoded[salonId];
    if (records is! List) {
      return const [];
    }
    return records
        .whereType<Map>()
        .map(
            (item) => InventoryRecord.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((left, right) => left.productName.compareTo(right.productName));
  }

  Future<void> _saveInventory(
      String salonId, List<InventoryRecord> latestRecords) async {
    final raw = preferences.getString(_inventoryKey);
    final allInventory = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    final existing = _loadInventory(salonId);
    final byProduct = {
      for (final record in existing) record.productId: record,
      for (final record in latestRecords) record.productId: record,
    };
    allInventory[salonId] =
        byProduct.values.map((record) => record.toJson()).toList();
    await preferences.setString(_inventoryKey, jsonEncode(allInventory));
  }

  Future<void> _replaceInventory(
      String salonId, List<InventoryRecord> latestRecords) async {
    final raw = preferences.getString(_inventoryKey);
    final allInventory = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    allInventory[salonId] =
        latestRecords.map((record) => record.toJson()).toList();
    await preferences.setString(_inventoryKey, jsonEncode(allInventory));
  }

  List<InventoryRecord> _recordsFromScan(InventoryScan scan) {
    final grouped = <String, ScanProductResult>{};
    for (final product in scan.products) {
      final productId = product.matchedProductId?.isNotEmpty == true
          ? product.matchedProductId!
          : 'manual_${product.confirmedName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
      final existing = grouped[productId];
      grouped[productId] = existing == null
          ? product.copyWith(matchedProductId: productId)
          : existing.copyWith(
              confirmedQuantity:
                  existing.confirmedQuantity + product.confirmedQuantity);
    }
    return grouped.entries.map((entry) {
      final product = entry.value;
      return InventoryRecord(
        productId: entry.key,
        productName: product.confirmedName,
        brand: product.brand,
        category: product.category,
        packagingType: product.packagingType,
        shadeCode: product.shadeCode,
        quantity: product.confirmedQuantity,
        latestScanDate: scan.createdAt,
      );
    }).toList();
  }

  void _emitCurrentState() {
    final rawScans = preferences.getString(_scansKey);
    final scans = rawScans == null || rawScans.isEmpty
        ? <InventoryScan>[]
        : (jsonDecode(rawScans) as List)
            .whereType<Map>()
            .map((item) =>
                InventoryScan.fromJson(Map<String, dynamic>.from(item)))
            .toList();
    _scanController.add(scans);

    final rawInventory = preferences.getString(_inventoryKey);
    final inventory = <InventoryRecord>[];
    if (rawInventory != null && rawInventory.isNotEmpty) {
      final decoded = jsonDecode(rawInventory);
      if (decoded is Map) {
        for (final records in decoded.values) {
          if (records is List) {
            inventory.addAll(records.whereType<Map>().map((item) =>
                InventoryRecord.fromJson(Map<String, dynamic>.from(item))));
          }
        }
      }
    }
    _inventoryController.add(inventory);
  }
}
