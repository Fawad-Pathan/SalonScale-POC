import 'package:flutter_test/flutter_test.dart';
import 'package:salonscale_poc/core/errors/app_exception.dart';
import 'package:salonscale_poc/features/scanning/models/scan_analysis_result.dart';

void main() {
  test('parses strict AI JSON and calculates totals', () {
    const raw = '''
    {
      "scanQuality": "good",
      "warnings": [],
      "detectedProducts": [
        {
          "temporaryId": "detected_001",
          "detectedName": "Sample Brand Colour Cream",
          "matchedProductId": "product_001",
          "brand": "Sample Brand",
          "category": "Hair Colour",
          "packagingType": "tube",
          "shadeCode": "5N",
          "quantity": 3,
          "recognitionConfidence": 0.91,
          "catalogueMatchConfidence": 0.88,
          "notes": "Three tubes visible."
        }
      ]
    }
    ''';

    final result = ScanAnalysisResult.fromAiResponse(raw);

    expect(result.scanQuality, 'good');
    expect(result.detectedProducts.single.quantity, 3);
    expect(result.totalUnits, 3);
  });

  test('rejects invalid JSON', () {
    expect(
      () => ScanAnalysisResult.fromAiResponse('not json'),
      throwsA(isA<AnalysisException>()),
    );
  });

  test('rejects missing detected product fields', () {
    const raw = '''
    {
      "scanQuality": "good",
      "warnings": [],
      "detectedProducts": [
        {
          "temporaryId": "detected_001",
          "detectedName": "Incomplete"
        }
      ]
    }
    ''';

    expect(
      () => ScanAnalysisResult.fromAiResponse(raw),
      throwsA(isA<AnalysisException>()),
    );
  });
}
