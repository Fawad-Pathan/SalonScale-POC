import 'dart:io';

import '../../catalogue/models/salon_product.dart';
import '../models/scan_analysis_result.dart';
import 'product_recognition_service.dart';

class MockProductRecognitionService implements ProductRecognitionService {
  const MockProductRecognitionService();

  @override
  Future<ScanAnalysisResult> analyzeImage({
    required File image,
    required List<SalonProduct> catalogue,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const ScanAnalysisResult(
      scanQuality: 'unknown',
      warnings: [
        'Mock analysis mode is enabled, so no live products were identified.'
      ],
      detectedProducts: [],
    );
  }
}
