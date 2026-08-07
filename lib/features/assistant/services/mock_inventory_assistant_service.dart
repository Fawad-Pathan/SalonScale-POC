import 'package:intl/intl.dart';

import '../../inventory/models/inventory_record.dart';
import '../../scanning/models/inventory_scan.dart';
import 'inventory_assistant_service.dart';

class MockInventoryAssistantService implements InventoryAssistantService {
  const MockInventoryAssistantService();

  @override
  Future<String> answerQuestion({
    required String question,
    required List<InventoryRecord> inventory,
    required List<InventoryScan> scans,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final normalized = question.toLowerCase();
    if (inventory.isEmpty && scans.isEmpty) {
      return 'No completed scans are saved yet. Run a scan first, then I can summarize products, low stock, shade codes, and scan history.';
    }

    if (normalized.contains('latest') || normalized.contains('last scan')) {
      return _latestScan(scans);
    }
    if (normalized.contains('running low') ||
        normalized.contains('fewer than') ||
        normalized.contains('less than')) {
      return _lowStock(inventory);
    }
    if (normalized.contains('shade')) {
      return _shadeCodes(inventory);
    }
    if (normalized.contains('colour tube') ||
        normalized.contains('color tube') ||
        normalized.contains('tube')) {
      return _tubeCount(scans);
    }
    if (normalized.contains('most often') ||
        normalized.contains('detected most')) {
      return _mostDetected(scans);
    }

    final totalUnits =
        inventory.fold<int>(0, (total, record) => total + record.quantity);
    final products = inventory
        .map((record) => '${record.productName} (${record.quantity})')
        .take(6)
        .join(', ');
    return 'Current mock inventory has $totalUnits units across ${inventory.length} products. Top entries: $products.';
  }

  String _latestScan(List<InventoryScan> scans) {
    if (scans.isEmpty) {
      return 'No scans have been completed yet.';
    }
    final scan = scans.first;
    final products = scan.products
        .map((product) =>
            '${product.confirmedQuantity} x ${product.confirmedName}${product.shadeCode.isEmpty ? '' : ' ${product.shadeCode}'}')
        .join(', ');
    return 'The latest scan on ${DateFormat.yMMMd().add_jm().format(scan.createdAt)} found $products.';
  }

  String _lowStock(List<InventoryRecord> inventory) {
    final low = inventory.where((record) => record.quantity < 3).toList();
    if (low.isEmpty) {
      return 'No saved inventory items are below three units.';
    }
    return 'Products below three units: ${low.map((record) => '${record.productName} (${record.quantity})').join(', ')}.';
  }

  String _shadeCodes(List<InventoryRecord> inventory) {
    final shades = inventory
        .map((record) => record.shadeCode)
        .where((shade) => shade.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (shades.isEmpty) {
      return 'No shade codes are saved in current inventory yet.';
    }
    return 'Saved shade codes: ${shades.join(', ')}.';
  }

  String _tubeCount(List<InventoryScan> scans) {
    final since = DateTime.now().subtract(const Duration(days: 7));
    var total = 0;
    for (final scan in scans.where((scan) => scan.createdAt.isAfter(since))) {
      for (final product in scan.products) {
        if (product.packagingType.toLowerCase() == 'tube' ||
            product.confirmedName.toLowerCase().contains('colour')) {
          total += product.confirmedQuantity;
        }
      }
    }
    return '$total colour tube units were scanned in the last seven days.';
  }

  String _mostDetected(List<InventoryScan> scans) {
    final counts = <String, int>{};
    for (final scan in scans) {
      for (final product in scan.products) {
        counts[product.confirmedName] =
            (counts[product.confirmedName] ?? 0) + product.confirmedQuantity;
      }
    }
    if (counts.isEmpty) {
      return 'No products have been detected yet.';
    }
    final sorted = counts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return 'Most detected products: ${sorted.take(5).map((entry) => '${entry.key} (${entry.value})').join(', ')}.';
  }
}
