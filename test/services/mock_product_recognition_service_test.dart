import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:salonscale_poc/features/catalogue/models/salon_product.dart';
import 'package:salonscale_poc/features/scanning/services/mock_product_recognition_service.dart';

void main() {
  test('mock recognition does not invent demo products', () async {
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
    ];

    const service = MockProductRecognitionService();
    final result = await service.analyzeImage(
        image: File('unused.jpg'), catalogue: catalogue);

    expect(result.detectedProducts, isEmpty);
    expect(result.totalUnits, 0);
    expect(result.warnings.single, contains('Mock analysis mode'));
  });
}
