import 'package:collection/collection.dart';

import '../../../core/utils/json_helpers.dart';
import 'scan_product_result.dart';

class InventoryScan {
  const InventoryScan({
    required this.id,
    required this.userId,
    required this.salonId,
    required this.imageUrl,
    required this.localImagePath,
    required this.createdAt,
    required this.status,
    required this.scanQuality,
    required this.totalUniqueProducts,
    required this.totalUnits,
    required this.warnings,
    required this.products,
  });

  final String id;
  final String userId;
  final String salonId;
  final String imageUrl;
  final String localImagePath;
  final DateTime createdAt;
  final String status;
  final String scanQuality;
  final int totalUniqueProducts;
  final int totalUnits;
  final List<String> warnings;
  final List<ScanProductResult> products;

  factory InventoryScan.fromJson(Map<String, dynamic> json) {
    final products =
        readMapList(json, 'products').map(ScanProductResult.fromJson).toList();
    return InventoryScan(
      id: readString(json, 'id'),
      userId: readString(json, 'userId'),
      salonId: readString(json, 'salonId'),
      imageUrl: readString(json, 'imageUrl'),
      localImagePath: readString(json, 'localImagePath'),
      createdAt: parseDateTime(json['createdAt'], fallback: DateTime.now()),
      status: readString(json, 'status', fallback: 'completed'),
      scanQuality: readString(json, 'scanQuality', fallback: 'unknown'),
      totalUniqueProducts:
          readInt(json, 'totalUniqueProducts', fallback: products.length),
      totalUnits: readInt(
        json,
        'totalUnits',
        fallback: products.fold<int>(
            0, (total, product) => total + product.confirmedQuantity),
      ),
      warnings: readStringList(json, 'warnings'),
      products: products,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'salonId': salonId,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'scanQuality': scanQuality,
      'totalUniqueProducts': totalUniqueProducts,
      'totalUnits': totalUnits,
      'warnings': warnings,
      'products': products.map((product) => product.toJson()).toList(),
    };
  }

  Map<String, dynamic> toFirestoreJson() => toJson()..remove('localImagePath');

  InventoryScan copyWith({
    String? id,
    String? userId,
    String? salonId,
    String? imageUrl,
    String? localImagePath,
    DateTime? createdAt,
    String? status,
    String? scanQuality,
    int? totalUniqueProducts,
    int? totalUnits,
    List<String>? warnings,
    List<ScanProductResult>? products,
  }) {
    return InventoryScan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      salonId: salonId ?? this.salonId,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      scanQuality: scanQuality ?? this.scanQuality,
      totalUniqueProducts: totalUniqueProducts ?? this.totalUniqueProducts,
      totalUnits: totalUnits ?? this.totalUnits,
      warnings: warnings ?? this.warnings,
      products: products ?? this.products,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InventoryScan &&
            other.id == id &&
            other.userId == userId &&
            other.salonId == salonId &&
            other.imageUrl == imageUrl &&
            other.localImagePath == localImagePath &&
            other.createdAt == createdAt &&
            other.status == status &&
            other.scanQuality == scanQuality &&
            other.totalUniqueProducts == totalUniqueProducts &&
            other.totalUnits == totalUnits &&
            const ListEquality<String>().equals(other.warnings, warnings) &&
            const ListEquality<ScanProductResult>()
                .equals(other.products, products);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      salonId,
      imageUrl,
      localImagePath,
      createdAt,
      status,
      scanQuality,
      totalUniqueProducts,
      totalUnits,
      Object.hashAll(warnings),
      Object.hashAll(products),
    );
  }
}
