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
You are analyzing a salon backbar inventory image. Analyze the entire image from edge to edge, not only the center of the frame. Identify only products clearly visible in the image. Match products against the supplied product catalogue. Products may have visually similar packaging but different shade codes. Read shade codes carefully. Estimate the number of visible units. Do not invent products. When uncertain, return null for the matched product ID and explain the uncertainty in the warnings array. Return valid JSON only.
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
