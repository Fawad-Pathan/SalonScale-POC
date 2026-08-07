import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salonscale_poc/features/catalogue/models/salon_product.dart';
import 'package:salonscale_poc/features/scanning/services/openai_product_recognition_service.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('openai_scan_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('sends an image to OpenAI and parses structured scan results', () async {
    final image = File('${tempDir.path}/capture.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);

    const catalogue = [
      SalonProduct(
        id: 'color_5n',
        name: 'Professional Colour Cream 5N',
        brand: 'Sample Brand',
        category: 'Hair Colour',
        packagingType: 'tube',
        shadeCode: '5N',
        aliases: ['Colour Cream 5N'],
        imageUrl: '',
      ),
    ];

    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://api.openai.com/v1/responses');
      expect(
          request.headers['Authorization'] ?? request.headers['authorization'],
          'Bearer test-key');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['model'], 'test-model');
      expect(body['store'], isFalse);
      expect(
        (((body['text'] as Map)['format'] as Map)['schema'] as Map)['required'],
        contains('detectedProducts'),
      );

      final content = ((body['input'] as List).first
          as Map<String, dynamic>)['content'] as List;
      expect((content.first as Map)['type'], 'input_text');
      expect((content.last as Map)['image_url'],
          startsWith('data:image/jpeg;base64,'));

      final analysis = jsonEncode({
        'scanQuality': 'good',
        'warnings': <String>[],
        'detectedProducts': [
          {
            'temporaryId': 'detected_001',
            'detectedName': 'Professional Colour Cream 5N',
            'matchedProductId': 'color_5n',
            'brand': 'Sample Brand',
            'category': 'Hair Colour',
            'packagingType': 'tube',
            'shadeCode': '5N',
            'quantity': 2,
            'recognitionConfidence': 0.91,
            'catalogueMatchConfidence': 0.88,
            'notes': 'Two tubes visible.',
            'matchStatus': 'matched',
            'warnings': <String>[],
          },
        ],
      });

      return http.Response(
        jsonEncode({
          'output': [
            {
              'type': 'message',
              'content': [
                {'type': 'output_text', 'text': analysis},
              ],
            },
          ],
        }),
        200,
      );
    });

    final service = OpenAIProductRecognitionService(
      apiKey: 'test-key',
      model: 'test-model',
      client: client,
    );

    final result =
        await service.analyzeImage(image: image, catalogue: catalogue);

    expect(result.scanQuality, 'good');
    expect(result.detectedProducts.single.matchedProductId, 'color_5n');
    expect(result.detectedProducts.single.quantity, 2);
  });
}
