import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../inventory/models/inventory_record.dart';
import '../../scanning/models/inventory_scan.dart';
import '../../scanning/models/scan_product_result.dart';
import 'inventory_repository.dart';

class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  @override
  Stream<List<InventoryScan>> watchScans(String salonId) {
    return _scanCollection(salonId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  InventoryScan.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  @override
  Stream<List<InventoryRecord>> watchInventory(String salonId) {
    return _inventoryCollection(salonId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => InventoryRecord.fromJson(
                  {...doc.data(), 'productId': doc.id}))
              .toList()
            ..sort(
                (left, right) => left.productName.compareTo(right.productName)),
        );
  }

  @override
  Future<List<InventoryScan>> getScans(String salonId) async {
    final snapshot = await _scanCollection(salonId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => InventoryScan.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<InventoryRecord>> getInventory(String salonId) async {
    final snapshot = await _inventoryCollection(salonId).get();
    return snapshot.docs
        .map((doc) =>
            InventoryRecord.fromJson({...doc.data(), 'productId': doc.id}))
        .toList();
  }

  @override
  Future<InventoryScan?> getScan(
      {required String salonId, required String scanId}) async {
    final doc = await _scanCollection(salonId).doc(scanId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return InventoryScan.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<void> saveScan(InventoryScan scan, {File? image}) async {
    var scanToSave = scan;
    if (image != null && image.existsSync()) {
      final ref = storage.ref('salons/${scan.salonId}/scans/${scan.id}.jpg');
      await ref.putFile(image);
      scanToSave = scan.copyWith(imageUrl: await ref.getDownloadURL());
    }

    final batch = firestore.batch();
    batch.set(_scanCollection(scan.salonId).doc(scan.id),
        scanToSave.toFirestoreJson());
    for (final record in _recordsFromScan(scanToSave)) {
      batch.set(_inventoryCollection(scan.salonId).doc(record.productId),
          record.toFirestoreJson());
    }
    await batch.commit();
  }

  @override
  Future<void> deleteScan(
      {required String salonId, required String scanId}) async {
    await _scanCollection(salonId).doc(scanId).delete();

    final inventoryDocs = await _inventoryCollection(salonId).get();
    final latestScans = await _scanCollection(salonId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    final batch = firestore.batch();
    for (final doc in inventoryDocs.docs) {
      batch.delete(doc.reference);
    }
    if (latestScans.docs.isNotEmpty) {
      final latest = InventoryScan.fromJson({
        ...latestScans.docs.first.data(),
        'id': latestScans.docs.first.id,
      });
      for (final record in _recordsFromScan(latest)) {
        batch.set(_inventoryCollection(salonId).doc(record.productId),
            record.toFirestoreJson());
      }
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _scanCollection(String salonId) {
    return firestore.collection('salons').doc(salonId).collection('scans');
  }

  CollectionReference<Map<String, dynamic>> _inventoryCollection(
      String salonId) {
    return firestore.collection('salons').doc(salonId).collection('inventory');
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
}
