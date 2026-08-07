import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salonscale_poc/features/inventory/services/local_inventory_repository.dart';
import 'package:salonscale_poc/features/scanning/models/inventory_scan.dart';
import 'package:salonscale_poc/features/scanning/models/scan_product_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saving a scan preserves history and updates latest inventory count',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalInventoryRepository(preferences);

    final firstScan =
        _scan(id: 'scan_001', quantity: 5, createdAt: DateTime(2026, 7, 10));
    final secondScan =
        _scan(id: 'scan_002', quantity: 2, createdAt: DateTime(2026, 7, 11));

    await repository.saveScan(firstScan);
    await repository.saveScan(secondScan);

    final scans = await repository.getScans('demo_salon');
    final inventory = await repository.getInventory('demo_salon');

    expect(scans, hasLength(2));
    expect(inventory.single.quantity, 2);
    expect(inventory.single.latestScanDate, DateTime(2026, 7, 11));
  });
}

InventoryScan _scan({
  required String id,
  required int quantity,
  required DateTime createdAt,
}) {
  return InventoryScan(
    id: id,
    userId: 'user_001',
    salonId: 'demo_salon',
    imageUrl: '',
    localImagePath: '',
    createdAt: createdAt,
    status: 'completed',
    scanQuality: 'good',
    totalUniqueProducts: 1,
    totalUnits: quantity,
    warnings: const [],
    products: [
      ScanProductResult(
        temporaryId: 'detected_001',
        detectedName: 'Professional Colour Cream 5N',
        confirmedName: 'Professional Colour Cream 5N',
        originalQuantity: quantity,
        confirmedQuantity: quantity,
        matchedProductId: 'product_001',
        brand: 'Sample Brand',
        category: 'Hair Colour',
        packagingType: 'tube',
        shadeCode: '5N',
        recognitionConfidence: 0.9,
        catalogueMatchConfidence: 0.9,
        wasCorrected: false,
        notes: '',
        warnings: const [],
      ),
    ],
  );
}
