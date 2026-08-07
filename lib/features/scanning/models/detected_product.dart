import 'package:collection/collection.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/json_helpers.dart';

class NormalizedBoundingBox {
  const NormalizedBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  factory NormalizedBoundingBox.fromJson(Map<String, dynamic> json) {
    return NormalizedBoundingBox(
      left: readDouble(json, 'left'),
      top: readDouble(json, 'top'),
      width: readDouble(json, 'width'),
      height: readDouble(json, 'height'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  NormalizedBoundingBox clamp() {
    return NormalizedBoundingBox(
      left: left.clamp(0, 1).toDouble(),
      top: top.clamp(0, 1).toDouble(),
      width: width.clamp(0.05, 1).toDouble(),
      height: height.clamp(0.05, 1).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NormalizedBoundingBox &&
            other.left == left &&
            other.top == top &&
            other.width == width &&
            other.height == height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);
}

class DetectedProduct {
  const DetectedProduct({
    required this.temporaryId,
    required this.detectedName,
    required this.brand,
    required this.category,
    required this.packagingType,
    required this.shadeCode,
    required this.quantity,
    required this.recognitionConfidence,
    required this.catalogueMatchConfidence,
    required this.notes,
    this.matchedProductId,
    this.matchStatus = 'needs_review',
    this.warnings = const [],
    this.normalizedBoundingBox,
    this.cameraCropPath,
  });

  final String temporaryId;
  final String detectedName;
  final String? matchedProductId;
  final String brand;
  final String category;
  final String packagingType;
  final String shadeCode;
  final int quantity;
  final double recognitionConfidence;
  final double catalogueMatchConfidence;
  final String notes;
  final String matchStatus;
  final List<String> warnings;
  final NormalizedBoundingBox? normalizedBoundingBox;
  final String? cameraCropPath;

  factory DetectedProduct.fromJson(Map<String, dynamic> json) {
    return DetectedProduct(
      temporaryId: readString(json, 'temporaryId'),
      detectedName: readString(json, 'detectedName'),
      matchedProductId: readNullableString(json, 'matchedProductId'),
      brand: readString(json, 'brand'),
      category: readString(json, 'category'),
      packagingType: readString(json, 'packagingType'),
      shadeCode: readString(json, 'shadeCode'),
      quantity: readInt(json, 'quantity', fallback: 1),
      recognitionConfidence: readDouble(json, 'recognitionConfidence'),
      catalogueMatchConfidence: readDouble(json, 'catalogueMatchConfidence'),
      notes: readString(json, 'notes'),
      matchStatus: readString(json, 'matchStatus', fallback: 'needs_review'),
      warnings: readStringList(json, 'warnings'),
      normalizedBoundingBox:
          mapFromDynamic(json['normalizedBoundingBox']).isEmpty
              ? null
              : NormalizedBoundingBox.fromJson(
                      mapFromDynamic(json['normalizedBoundingBox']))
                  .clamp(),
      cameraCropPath: readNullableString(json, 'cameraCropPath'),
    );
  }

  factory DetectedProduct.fromStrictJson(Map<String, dynamic> json) {
    const requiredFields = [
      'temporaryId',
      'detectedName',
      'brand',
      'category',
      'packagingType',
      'quantity',
      'recognitionConfidence',
      'catalogueMatchConfidence',
    ];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw AnalysisException(
            'AI response is missing required detected product field: $field');
      }
    }
    final product = DetectedProduct.fromJson(json);
    if (product.detectedName.trim().isEmpty) {
      throw const AnalysisException(
          'AI response included a detected product with an empty name.');
    }
    if (product.quantity < 0) {
      throw const AnalysisException(
          'AI response included a negative product quantity.');
    }
    if (product.recognitionConfidence < 0 ||
        product.recognitionConfidence > 1) {
      throw const AnalysisException(
          'Recognition confidence must be between 0 and 1.');
    }
    if (product.catalogueMatchConfidence < 0 ||
        product.catalogueMatchConfidence > 1) {
      throw const AnalysisException(
          'Catalogue match confidence must be between 0 and 1.');
    }
    return product;
  }

  Map<String, dynamic> toJson() {
    return {
      'temporaryId': temporaryId,
      'detectedName': detectedName,
      'matchedProductId': matchedProductId,
      'brand': brand,
      'category': category,
      'packagingType': packagingType,
      'shadeCode': shadeCode,
      'quantity': quantity,
      'recognitionConfidence': recognitionConfidence,
      'catalogueMatchConfidence': catalogueMatchConfidence,
      'notes': notes,
      'matchStatus': matchStatus,
      'warnings': warnings,
      if (normalizedBoundingBox != null)
        'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
      if (cameraCropPath != null) 'cameraCropPath': cameraCropPath,
    };
  }

  DetectedProduct copyWith({
    String? temporaryId,
    String? detectedName,
    String? matchedProductId,
    bool clearMatchedProductId = false,
    String? brand,
    String? category,
    String? packagingType,
    String? shadeCode,
    int? quantity,
    double? recognitionConfidence,
    double? catalogueMatchConfidence,
    String? notes,
    String? matchStatus,
    List<String>? warnings,
    NormalizedBoundingBox? normalizedBoundingBox,
    String? cameraCropPath,
  }) {
    return DetectedProduct(
      temporaryId: temporaryId ?? this.temporaryId,
      detectedName: detectedName ?? this.detectedName,
      matchedProductId: clearMatchedProductId
          ? null
          : matchedProductId ?? this.matchedProductId,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      packagingType: packagingType ?? this.packagingType,
      shadeCode: shadeCode ?? this.shadeCode,
      quantity: quantity ?? this.quantity,
      recognitionConfidence:
          recognitionConfidence ?? this.recognitionConfidence,
      catalogueMatchConfidence:
          catalogueMatchConfidence ?? this.catalogueMatchConfidence,
      notes: notes ?? this.notes,
      matchStatus: matchStatus ?? this.matchStatus,
      warnings: warnings ?? this.warnings,
      normalizedBoundingBox:
          normalizedBoundingBox ?? this.normalizedBoundingBox,
      cameraCropPath: cameraCropPath ?? this.cameraCropPath,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DetectedProduct &&
            other.temporaryId == temporaryId &&
            other.detectedName == detectedName &&
            other.matchedProductId == matchedProductId &&
            other.brand == brand &&
            other.category == category &&
            other.packagingType == packagingType &&
            other.shadeCode == shadeCode &&
            other.quantity == quantity &&
            other.recognitionConfidence == recognitionConfidence &&
            other.catalogueMatchConfidence == catalogueMatchConfidence &&
            other.notes == notes &&
            other.matchStatus == matchStatus &&
            const ListEquality<String>().equals(other.warnings, warnings) &&
            other.normalizedBoundingBox == normalizedBoundingBox &&
            other.cameraCropPath == cameraCropPath;
  }

  @override
  int get hashCode {
    return Object.hash(
      temporaryId,
      detectedName,
      matchedProductId,
      brand,
      category,
      packagingType,
      shadeCode,
      quantity,
      recognitionConfidence,
      catalogueMatchConfidence,
      notes,
      matchStatus,
      Object.hashAll(warnings),
      normalizedBoundingBox,
      cameraCropPath,
    );
  }
}
