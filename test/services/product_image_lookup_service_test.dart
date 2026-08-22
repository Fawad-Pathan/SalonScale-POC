import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salonscale_poc/features/scanning/models/scan_product_result.dart';
import 'package:salonscale_poc/features/scanning/services/product_image_lookup_service.dart';

void main() {
  test('returns the first direct product image from Open Facts sources',
      () async {
    final service = ProductImageLookupService(
      client: MockClient((request) async {
        expect(request.url.host, 'world.openbeautyfacts.org');
        return http.Response(
          '''
          {
            "products": [
              {
                "product_name": "Aestura Atobarrier 365 Cream",
                "brands": "Aestura",
                "image_front_url": "https://images.example/aestura.jpg"
              }
            ]
          }
          ''',
          200,
        );
      }),
    );

    final image = await service.lookup(_product(
      name: 'Aestura Atobarrier 365 Cream',
      brand: 'Aestura',
    ));

    expect(image?.imageUrl, 'https://images.example/aestura.jpg');
    expect(image?.sourceLabel, 'Open Beauty Facts');
  });

  test('falls back to a Wikimedia thumbnail when product databases miss',
      () async {
    final service = ProductImageLookupService(
      client: MockClient((request) async {
        if (request.url.host.startsWith('world.open')) {
          return http.Response('{"products":[]}', 200);
        }
        if (request.url.path == '/w/api.php') {
          return http.Response(
            '{"query":{"search":[{"title":"Coca-Cola"}]}}',
            200,
          );
        }
        return http.Response(
          '{"thumbnail":{"source":"https://upload.wikimedia.org/coke.png"}}',
          200,
        );
      }),
    );

    final image = await service.lookup(_product(
      name: 'Coca-Cola Classic',
      brand: 'Coca-Cola',
    ));

    expect(image?.imageUrl, 'https://upload.wikimedia.org/coke.png');
    expect(image?.sourceLabel, 'Wikimedia');
  });
}

ScanProductResult _product({
  required String name,
  required String brand,
}) {
  return ScanProductResult(
    temporaryId: 'test',
    detectedName: name,
    confirmedName: name,
    originalQuantity: 1,
    confirmedQuantity: 1,
    brand: brand,
    category: 'Skincare',
    packagingType: 'Tube',
    shadeCode: '',
    recognitionConfidence: 0.92,
    catalogueMatchConfidence: 0,
    wasCorrected: false,
    notes: '',
    warnings: const [],
  );
}
