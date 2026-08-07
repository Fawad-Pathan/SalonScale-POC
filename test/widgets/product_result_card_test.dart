import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salonscale_poc/features/catalogue/models/salon_product.dart';
import 'package:salonscale_poc/features/scanning/models/scan_product_result.dart';
import 'package:salonscale_poc/features/scanning/presentation/product_result_card.dart';

void main() {
  testWidgets('stylist can edit scan result name and quantity', (tester) async {
    ScanProductResult? updated;
    const product = ScanProductResult(
      temporaryId: 'detected_001',
      detectedName: 'Sample Colour Tube',
      confirmedName: 'Sample Colour Tube',
      originalQuantity: 2,
      confirmedQuantity: 2,
      matchedProductId: 'product_001',
      brand: 'Sample Brand',
      category: 'Hair Colour',
      packagingType: 'tube',
      shadeCode: '5N',
      recognitionConfidence: 0.82,
      catalogueMatchConfidence: 0.8,
      wasCorrected: false,
      notes: '',
      warnings: [],
    );
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductResultCard(
            product: product,
            catalogue: catalogue,
            onChanged: (value) => updated = value,
            onDeleted: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('edit-product-name')),
        'Corrected Colour Cream 5N');
    await tester.enterText(find.byKey(const Key('edit-product-quantity')), '4');
    await tester.tap(find.byKey(const Key('save-product-edit')));
    await tester.pumpAndSettle();

    expect(updated?.confirmedName, 'Corrected Colour Cream 5N');
    expect(updated?.confirmedQuantity, 4);
    expect(updated?.wasCorrected, true);
  });
}
