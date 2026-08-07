import 'dart:io';

import '../../catalogue/models/salon_product.dart';
import '../models/scan_analysis_result.dart';

abstract class ProductRecognitionService {
  Future<ScanAnalysisResult> analyzeImage({
    required File image,
    required List<SalonProduct> catalogue,
  });
}
