import 'package:flutter_test/flutter_test.dart';
import 'package:salonscale_poc/features/catalogue/models/salon_product.dart';
import 'package:salonscale_poc/features/scanning/models/detected_product.dart';
import 'package:salonscale_poc/features/scanning/models/scan_analysis_result.dart';
import 'package:salonscale_poc/features/scanning/services/product_matcher.dart';

void main() {
  const catalogue = [
    SalonProduct(
      id: 'product_001',
      name: 'Professional Colour Cream 5N',
      brand: 'Sample Brand',
      category: 'Hair Colour',
      packagingType: 'tube',
      shadeCode: '5N',
      aliases: ['Colour Cream 5N'],
      imageUrl: '',
    ),
    SalonProduct(
      id: 'product_002',
      name: 'Professional Colour Cream 6N',
      brand: 'Sample Brand',
      category: 'Hair Colour',
      packagingType: 'tube',
      shadeCode: '6N',
      aliases: ['Colour Cream 6N'],
      imageUrl: '',
    ),
  ];

  test('uses shade code to distinguish similar products', () {
    const matcher = ProductMatcher();
    const detected = DetectedProduct(
      temporaryId: 'detected_001',
      detectedName: 'Sample Brand Colour Cream',
      brand: 'Sample Brand',
      category: 'Hair Colour',
      packagingType: 'tube',
      shadeCode: '5N',
      quantity: 1,
      recognitionConfidence: 0.9,
      catalogueMatchConfidence: 0.4,
      notes: '',
    );

    final match = matcher.findBestMatch(detected, catalogue);

    expect(match?.product.id, 'product_001');
    expect(match?.score, greaterThan(0.7));
  });

  test('merges duplicate detections and sums quantity', () {
    const matcher = ProductMatcher();
    final merged = matcher.mergeDuplicateDetections(
      const [
        DetectedProduct(
          temporaryId: 'a',
          detectedName: 'Colour Cream',
          matchedProductId: 'product_001',
          brand: 'Sample Brand',
          category: 'Hair Colour',
          packagingType: 'tube',
          shadeCode: '5N',
          quantity: 2,
          recognitionConfidence: 0.8,
          catalogueMatchConfidence: 0.8,
          notes: 'Left side.',
        ),
        DetectedProduct(
          temporaryId: 'b',
          detectedName: 'Colour Cream',
          matchedProductId: 'product_001',
          brand: 'Sample Brand',
          category: 'Hair Colour',
          packagingType: 'tube',
          shadeCode: '5N',
          quantity: 3,
          recognitionConfidence: 0.7,
          catalogueMatchConfidence: 0.7,
          notes: 'Right side.',
        ),
      ],
    );

    expect(merged, hasLength(1));
    expect(merged.single.quantity, 5);
  });

  test('keeps branded products outside the catalogue as unmatched inventory',
      () {
    const matcher = ProductMatcher();
    const result = ScanAnalysisResult(
      scanQuality: 'good',
      warnings: [],
      detectedProducts: [
        DetectedProduct(
          temporaryId: 'coke_001',
          detectedName: 'Coca-Cola Classic',
          brand: 'Coca-Cola',
          category: 'Beverage',
          packagingType: 'bottle',
          shadeCode: '',
          quantity: 2,
          recognitionConfidence: 0.91,
          catalogueMatchConfidence: 0,
          notes: 'Two matching bottles visible, one partially behind another.',
        ),
      ],
    );

    final refined = matcher.refineAnalysis(result, catalogue);

    expect(refined.detectedProducts, hasLength(1));
    expect(refined.detectedProducts.single.detectedName, 'Coca-Cola Classic');
    expect(refined.detectedProducts.single.matchedProductId, isNull);
    expect(refined.detectedProducts.single.matchStatus, 'unmatched');
    expect(refined.detectedProducts.single.quantity, 2);
  });

  test('skips generic low-information object descriptions', () {
    const matcher = ProductMatcher();
    const result = ScanAnalysisResult(
      scanQuality: 'fair',
      warnings: [],
      detectedProducts: [
        DetectedProduct(
          temporaryId: 'generic_001',
          detectedName: 'White Dropper Bottle',
          brand: '',
          category: 'Skin Care',
          packagingType: 'dropper bottle',
          shadeCode: '',
          quantity: 1,
          recognitionConfidence: 0.74,
          catalogueMatchConfidence: 0,
          notes: 'No readable label text.',
        ),
      ],
    );

    final refined = matcher.refineAnalysis(result, catalogue);

    expect(refined.detectedProducts, isEmpty);
    expect(refined.warnings.single, contains('low-information'));
  });

  test('skips appearance-only container descriptions', () {
    const matcher = ProductMatcher();
    const result = ScanAnalysisResult(
      scanQuality: 'fair',
      warnings: [],
      detectedProducts: [
        DetectedProduct(
          temporaryId: 'generic_002',
          detectedName: 'Blue and White Container',
          brand: '',
          category: 'Skin Care',
          packagingType: 'container',
          shadeCode: '',
          quantity: 1,
          recognitionConfidence: 0.88,
          catalogueMatchConfidence: 0,
          notes: 'No readable product name or brand.',
        ),
      ],
    );

    final refined = matcher.refineAnalysis(result, catalogue);

    expect(refined.detectedProducts, isEmpty);
    expect(refined.warnings.single, contains('low-information'));
  });

  test('does not trust catalogue ids attached to generic descriptions', () {
    const matcher = ProductMatcher();
    const result = ScanAnalysisResult(
      scanQuality: 'fair',
      warnings: [],
      detectedProducts: [
        DetectedProduct(
          temporaryId: 'generic_003',
          detectedName: 'Blue and White Container',
          matchedProductId: 'product_001',
          brand: '',
          category: 'Hair Colour',
          packagingType: 'container',
          shadeCode: '',
          quantity: 1,
          recognitionConfidence: 0.91,
          catalogueMatchConfidence: 0.91,
          notes: 'No readable product name or brand.',
        ),
      ],
    );

    final refined = matcher.refineAnalysis(result, catalogue);

    expect(refined.detectedProducts, isEmpty);
  });

  test('keeps readable real product names even when outside catalogue', () {
    const matcher = ProductMatcher();
    const result = ScanAnalysisResult(
      scanQuality: 'good',
      warnings: [],
      detectedProducts: [
        DetectedProduct(
          temporaryId: 'aestura_001',
          detectedName: 'Aestura Atobarrier 365 Cream',
          brand: 'Aestura',
          category: 'Skincare',
          packagingType: 'tube',
          shadeCode: '',
          quantity: 1,
          recognitionConfidence: 0.86,
          catalogueMatchConfidence: 0,
          notes: 'Mirrored label text is readable.',
        ),
      ],
    );

    final refined = matcher.refineAnalysis(result, catalogue);

    expect(refined.detectedProducts, hasLength(1));
    expect(
      refined.detectedProducts.single.detectedName,
      'Aestura Atobarrier 365 Cream',
    );
  });
}
