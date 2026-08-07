import 'dart:convert';

import 'package:collection/collection.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/json_helpers.dart';
import 'detected_product.dart';

class ScanAnalysisResult {
  const ScanAnalysisResult({
    required this.scanQuality,
    required this.warnings,
    required this.detectedProducts,
  });

  final String scanQuality;
  final List<String> warnings;
  final List<DetectedProduct> detectedProducts;

  factory ScanAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ScanAnalysisResult(
      scanQuality: readString(json, 'scanQuality', fallback: 'unknown'),
      warnings: readStringList(json, 'warnings'),
      detectedProducts: readMapList(json, 'detectedProducts')
          .map(DetectedProduct.fromJson)
          .toList(),
    );
  }

  factory ScanAnalysisResult.fromStrictJson(Map<String, dynamic> json) {
    if (!json.containsKey('scanQuality')) {
      throw const AnalysisException('AI response is missing scanQuality.');
    }
    if (json['detectedProducts'] is! List) {
      throw const AnalysisException(
          'AI response must include detectedProducts as a list.');
    }
    return ScanAnalysisResult(
      scanQuality: readString(json, 'scanQuality', fallback: 'unknown'),
      warnings: readStringList(json, 'warnings'),
      detectedProducts: readMapList(json, 'detectedProducts')
          .map(DetectedProduct.fromStrictJson)
          .toList(),
    );
  }

  factory ScanAnalysisResult.fromAiResponse(String response) {
    if (response.trim().isEmpty) {
      throw const AnalysisException('AI response was empty.');
    }

    try {
      final decoded = jsonDecode(response);
      if (decoded is! Map) {
        throw const AnalysisException('AI response must be a JSON object.');
      }
      return ScanAnalysisResult.fromStrictJson(
          Map<String, dynamic>.from(decoded));
    } on FormatException catch (error) {
      throw AnalysisException('AI response was not valid JSON.', cause: error);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'scanQuality': scanQuality,
      'warnings': warnings,
      'detectedProducts':
          detectedProducts.map((product) => product.toJson()).toList(),
    };
  }

  int get totalUnits => detectedProducts.fold<int>(
      0, (total, product) => total + product.quantity);

  ScanAnalysisResult copyWith({
    String? scanQuality,
    List<String>? warnings,
    List<DetectedProduct>? detectedProducts,
  }) {
    return ScanAnalysisResult(
      scanQuality: scanQuality ?? this.scanQuality,
      warnings: warnings ?? this.warnings,
      detectedProducts: detectedProducts ?? this.detectedProducts,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScanAnalysisResult &&
            other.scanQuality == scanQuality &&
            const ListEquality<String>().equals(other.warnings, warnings) &&
            const ListEquality<DetectedProduct>()
                .equals(other.detectedProducts, detectedProducts);
  }

  @override
  int get hashCode => Object.hash(
      scanQuality, Object.hashAll(warnings), Object.hashAll(detectedProducts));
}
