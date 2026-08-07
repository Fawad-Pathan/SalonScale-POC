import 'dart:io';

import '../../inventory/models/inventory_record.dart';
import '../../scanning/models/inventory_scan.dart';

abstract class InventoryRepository {
  Stream<List<InventoryScan>> watchScans(String salonId);

  Stream<List<InventoryRecord>> watchInventory(String salonId);

  Future<List<InventoryScan>> getScans(String salonId);

  Future<List<InventoryRecord>> getInventory(String salonId);

  Future<InventoryScan?> getScan(
      {required String salonId, required String scanId});

  Future<void> saveScan(InventoryScan scan, {File? image});

  Future<void> deleteScan({required String salonId, required String scanId});
}
