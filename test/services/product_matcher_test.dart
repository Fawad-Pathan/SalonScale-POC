import 'package:flutter_test/flutter_test.dart';
import 'package:salonscale_poc/features/catalogue/models/salon_product.dart';
import 'package:salonscale_poc/features/scanning/models/detected_product.dart';
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
}
