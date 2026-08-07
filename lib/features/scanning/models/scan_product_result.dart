import 'package:collection/collection.dart';

import '../../../core/utils/json_helpers.dart';
import 'detected_product.dart';

class ScanProductResult {
  const ScanProductResult({
    required this.temporaryId,
    required this.detectedName,
    required this.confirmedName,
    required this.originalQuantity,
    required this.confirmedQuantity,
    required this.brand,
    required this.category,
    required this.packagingType,
    required this.shadeCode,
    required this.recognitionConfidence,
    required this.catalogueMatchConfidence,
    required this.wasCorrected,
    required this.notes,
    required this.warnings,
    this.matchedProductId,
    this.normalizedBoundingBox,
    this.cameraCropPath,
  });

  final String temporaryId;
  final String detectedName;
  final String confirmedName;
  final int originalQuantity;
  final int confirmedQuantity;
  final String? matchedProductId;
  final String brand;
  final String category;
  final String packagingType;
  final String shadeCode;
  final double recognitionConfidence;
  final double catalogueMatchConfidence;
  final bool wasCorrected;
  final String notes;
  final List<String> warnings;
  final NormalizedBoundingBox? normalizedBoundingBox;
  final String? cameraCropPath;

  factory ScanProductResult.fromDetected(DetectedProduct product) {
    return ScanProductResult(
      temporaryId: product.temporaryId,
      detectedName: product.detectedName,
      confirmedName: product.detectedName,
      originalQuantity: product.quantity,
      confirmedQuantity: product.quantity,
      matchedProductId: product.matchedProductId,
      brand: product.brand,
      category: product.category,
      packagingType: product.packagingType,
      shadeCode: product.shadeCode,
      recognitionConfidence: product.recognitionConfidence,
      catalogueMatchConfidence: product.catalogueMatchConfidence,
      wasCorrected: false,
      notes: product.notes,
      warnings: product.warnings,
      normalizedBoundingBox: product.normalizedBoundingBox,
      cameraCropPath: product.cameraCropPath,
    );
  }

  factory ScanProductResult.fromJson(Map<String, dynamic> json) {
    return ScanProductResult(
      temporaryId: readString(json, 'temporaryId'),
      detectedName: readString(json, 'detectedName'),
      confirmedName: readString(json, 'confirmedName',
          fallback: readString(json, 'detectedName')),
      originalQuantity: readInt(json, 'originalQuantity',
          fallback: readInt(json, 'quantity', fallback: 1)),
      confirmedQuantity: readInt(json, 'confirmedQuantity',
          fallback: readInt(json, 'quantity', fallback: 1)),
      matchedProductId: readNullableString(json, 'matchedProductId'),
      brand: readString(json, 'brand'),
      category: readString(json, 'category'),
      packagingType: readString(json, 'packagingType'),
      shadeCode: readString(json, 'shadeCode'),
      recognitionConfidence: readDouble(json, 'recognitionConfidence'),
      catalogueMatchConfidence: readDouble(json, 'catalogueMatchConfidence'),
      wasCorrected: readBool(json, 'wasCorrected'),
      notes: readString(json, 'notes'),
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

  Map<String, dynamic> toJson() {
    return {
      'temporaryId': temporaryId,
      'detectedName': detectedName,
      'confirmedName': confirmedName,
      'originalQuantity': originalQuantity,
      'confirmedQuantity': confirmedQuantity,
      'matchedProductId': matchedProductId,
      'brand': brand,
      'category': category,
      'packagingType': packagingType,
      'shadeCode': shadeCode,
      'recognitionConfidence': recognitionConfidence,
      'catalogueMatchConfidence': catalogueMatchConfidence,
      'wasCorrected': wasCorrected,
      'notes': notes,
      'warnings': warnings,
      if (normalizedBoundingBox != null)
        'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
      if (cameraCropPath != null) 'cameraCropPath': cameraCropPath,
    };
  }

  ScanProductResult copyWith({
    String? temporaryId,
    String? detectedName,
    String? confirmedName,
    int? originalQuantity,
    int? confirmedQuantity,
    String? matchedProductId,
    bool clearMatchedProductId = false,
    String? brand,
    String? category,
    String? packagingType,
    String? shadeCode,
    double? recognitionConfidence,
    double? catalogueMatchConfidence,
    bool? wasCorrected,
    String? notes,
    List<String>? warnings,
    NormalizedBoundingBox? normalizedBoundingBox,
    String? cameraCropPath,
  }) {
    final nextDetectedName = detectedName ?? this.detectedName;
    final nextConfirmedName = confirmedName ?? this.confirmedName;
    final nextOriginalQuantity = originalQuantity ?? this.originalQuantity;
    final nextQuantity = confirmedQuantity ?? this.confirmedQuantity;
    final nextMatchedProductId = clearMatchedProductId
        ? null
        : matchedProductId ?? this.matchedProductId;
    return ScanProductResult(
      temporaryId: temporaryId ?? this.temporaryId,
      detectedName: nextDetectedName,
      confirmedName: nextConfirmedName,
      originalQuantity: nextOriginalQuantity,
      confirmedQuantity: nextQuantity,
      matchedProductId: nextMatchedProductId,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      packagingType: packagingType ?? this.packagingType,
      shadeCode: shadeCode ?? this.shadeCode,
      recognitionConfidence:
          recognitionConfidence ?? this.recognitionConfidence,
      catalogueMatchConfidence:
          catalogueMatchConfidence ?? this.catalogueMatchConfidence,
      wasCorrected: wasCorrected ??
          (nextConfirmedName != nextDetectedName ||
              nextQuantity != nextOriginalQuantity ||
              nextMatchedProductId != this.matchedProductId),
      notes: notes ?? this.notes,
      warnings: warnings ?? this.warnings,
      normalizedBoundingBox:
          normalizedBoundingBox ?? this.normalizedBoundingBox,
      cameraCropPath: cameraCropPath ?? this.cameraCropPath,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScanProductResult &&
            other.temporaryId == temporaryId &&
            other.detectedName == detectedName &&
            other.confirmedName == confirmedName &&
            other.originalQuantity == originalQuantity &&
            other.confirmedQuantity == confirmedQuantity &&
            other.matchedProductId == matchedProductId &&
            other.brand == brand &&
            other.category == category &&
            other.packagingType == packagingType &&
            other.shadeCode == shadeCode &&
            other.recognitionConfidence == recognitionConfidence &&
            other.catalogueMatchConfidence == catalogueMatchConfidence &&
            other.wasCorrected == wasCorrected &&
            other.notes == notes &&
            const ListEquality<String>().equals(other.warnings, warnings) &&
            other.normalizedBoundingBox == normalizedBoundingBox &&
            other.cameraCropPath == cameraCropPath;
  }

  @override
  int get hashCode {
    return Object.hash(
      temporaryId,
      detectedName,
      confirmedName,
      originalQuantity,
      confirmedQuantity,
      matchedProductId,
      brand,
      category,
      packagingType,
      shadeCode,
      recognitionConfidence,
      catalogueMatchConfidence,
      wasCorrected,
      notes,
      Object.hashAll(warnings),
      normalizedBoundingBox,
      cameraCropPath,
    );
  }
}
