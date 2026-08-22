import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';
import '../../catalogue/models/salon_product.dart';
import '../models/scan_analysis_result.dart';
import 'product_matcher.dart';
import 'product_recognition_service.dart';

class APIProductRecognitionService implements ProductRecognitionService {
  APIProductRecognitionService({
    required this.endpoint,
    required this.apiKey,
    http.Client? client,
    this.matcher = const ProductMatcher(),
    this.timeout = const Duration(seconds: 35),
  }) : client = client ?? http.Client();

  final String endpoint;
  final String apiKey;
  final http.Client client;
  final ProductMatcher matcher;
  final Duration timeout;

  static const prompt = '''
You are the product recognition engine for a live store inventory scanner. Analyze the entire image from edge to edge, not only the center of the frame.

Identify real retail/product identity from visible text, logos, brand marks, product names, variants, shade codes, sizes, and distinctive packaging. Do not return generic object names like "red can", "white bottle", "tube", or "box" as inventory. If the product identity is not readable or strongly recognizable, skip that item or return it with low confidence and a specific warning.

Camera frames may come from mirrored webcams. If label text appears reversed, mentally unmirror it and use the corrected brand/product name. If the product is a real package with partially readable brand/product text, return the best supported identity with lower confidence and a warning instead of returning an empty list.

If the best available description is only color, shape, material, or packaging, for example "blue and white container", "plastic tube", or "white bottle", return no detected product for that object. Only return items that appear to be existing commercial products with a readable or strongly recognizable brand/product identity.

The supplied catalogue is optional reference data, not the complete product universe. Use a catalogue product ID only when visible evidence supports it. If the product is not in the catalogue, still identify it from the image, set matchedProductId to null, set matchStatus to unmatched, and fill brand/category/packagingType from the label and packaging.

Group identical visible units into one detectedProducts entry and set quantity to the visible count. Count partially occluded repeated units when enough visible label, silhouette, cap, colorway, or packaging evidence supports that they are the same product. Return separate entries for different products, variants, sizes, shades, or packaging types. Do not invent hidden products outside the image.

Return valid JSON only using the app schema.
''';

  @override
  Future<ScanAnalysisResult> analyzeImage({
    required File image,
    required List<SalonProduct> catalogue,
  }) async {
    if (endpoint.trim().isEmpty || apiKey.trim().isEmpty) {
      throw const AnalysisException(
          'AI endpoint and API key are required when mock mode is disabled.');
    }

    final request = http.MultipartRequest('POST', Uri.parse(endpoint));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['prompt'] = prompt;
    request.fields['responseFormat'] = 'json';
    request.fields['catalogue'] = jsonEncode(
      catalogue
          .map(
            (product) => {
              'id': product.id,
              'name': product.name,
              'brand': product.brand,
              'category': product.category,
              'packagingType': product.packagingType,
              'shadeCode': product.shadeCode,
              'aliases': product.aliases,
            },
          )
          .toList(),
    );
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    try {
      final streamed = await client.send(request).timeout(timeout);
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        throw AnalysisException(
            'AI analysis failed with status ${streamed.statusCode}: $body');
      }
      final extracted = _extractJsonResponse(body);
      return matcher.refineAnalysis(
          ScanAnalysisResult.fromAiResponse(extracted), catalogue);
    } on AnalysisException {
      rethrow;
    } on SocketException catch (error) {
      throw AnalysisException('Could not reach the AI analysis endpoint.',
          cause: error);
    } on TimeoutException catch (error) {
      throw AnalysisException('AI analysis timed out.', cause: error);
    } catch (error) {
      throw AnalysisException('AI analysis failed.', cause: error);
    }
  }

  String _extractJsonResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded.containsKey('scanQuality')) {
      return body;
    }
    if (decoded is Map && decoded['analysis'] is Map) {
      return jsonEncode(decoded['analysis']);
    }
    if (decoded is Map && decoded['content'] is String) {
      return decoded['content'].toString();
    }
    return body;
  }
}
