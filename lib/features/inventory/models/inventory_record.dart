import '../../../core/utils/json_helpers.dart';

class InventoryRecord {
  const InventoryRecord({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.category,
    required this.packagingType,
    required this.shadeCode,
    required this.quantity,
    required this.latestScanDate,
  });

  final String productId;
  final String productName;
  final String brand;
  final String category;
  final String packagingType;
  final String shadeCode;
  final int quantity;
  final DateTime latestScanDate;

  factory InventoryRecord.fromJson(Map<String, dynamic> json) {
    return InventoryRecord(
      productId: readString(json, 'productId'),
      productName: readString(json, 'productName'),
      brand: readString(json, 'brand'),
      category: readString(json, 'category'),
      packagingType: readString(json, 'packagingType'),
      shadeCode: readString(json, 'shadeCode'),
      quantity: readInt(json, 'quantity'),
      latestScanDate:
          parseDateTime(json['latestScanDate'], fallback: DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'brand': brand,
      'category': category,
      'packagingType': packagingType,
      'shadeCode': shadeCode,
      'quantity': quantity,
      'latestScanDate': latestScanDate.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreJson() => toJson();

  InventoryRecord copyWith({
    String? productId,
    String? productName,
    String? brand,
    String? category,
    String? packagingType,
    String? shadeCode,
    int? quantity,
    DateTime? latestScanDate,
  }) {
    return InventoryRecord(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      packagingType: packagingType ?? this.packagingType,
      shadeCode: shadeCode ?? this.shadeCode,
      quantity: quantity ?? this.quantity,
      latestScanDate: latestScanDate ?? this.latestScanDate,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InventoryRecord &&
            other.productId == productId &&
            other.productName == productName &&
            other.brand == brand &&
            other.category == category &&
            other.packagingType == packagingType &&
            other.shadeCode == shadeCode &&
            other.quantity == quantity &&
            other.latestScanDate == latestScanDate;
  }

  @override
  int get hashCode {
    return Object.hash(productId, productName, brand, category, packagingType,
        shadeCode, quantity, latestScanDate);
  }
}
