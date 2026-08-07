import 'dart:convert';

import 'package:intl/intl.dart';

import '../../inventory/models/inventory_record.dart';
import '../../scanning/models/inventory_scan.dart';

class AssistantContextBuilder {
  const AssistantContextBuilder();

  Map<String, dynamic> build({
    required List<InventoryRecord> inventory,
    required List<InventoryScan> scans,
  }) {
    final latestScan = scans.isEmpty ? null : scans.first;
    return {
      'latestScanDate': latestScan == null
          ? null
          : DateFormat('yyyy-MM-dd').format(latestScan.createdAt),
      'totalCompletedScans':
          scans.where((scan) => scan.status == 'completed').length,
      'inventory': inventory
          .map(
            (record) => {
              'productId': record.productId,
              'productName': record.productName,
              'brand': record.brand,
              'category': record.category,
              'packagingType': record.packagingType,
              'shadeCode': record.shadeCode,
              'quantity': record.quantity,
              'latestScanDate':
                  DateFormat('yyyy-MM-dd').format(record.latestScanDate),
            },
          )
          .toList(),
      'recentScans': scans
          .take(5)
          .map(
            (scan) => {
              'id': scan.id,
              'createdAt': scan.createdAt.toIso8601String(),
              'totalUnits': scan.totalUnits,
              'totalUniqueProducts': scan.totalUniqueProducts,
              'products': scan.products
                  .map(
                    (product) => {
                      'name': product.confirmedName,
                      'quantity': product.confirmedQuantity,
                      'shadeCode': product.shadeCode,
                      'matchedProductId': product.matchedProductId,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
  }

  String toCompactJson({
    required List<InventoryRecord> inventory,
    required List<InventoryScan> scans,
  }) {
    return jsonEncode(build(inventory: inventory, scans: scans));
  }
}
