import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';
import '../../catalogue/models/salon_product.dart';
import '../models/scan_analysis_result.dart';
import 'product_matcher.dart';
import 'product_recognition_service.dart';

class OpenAIProductRecognitionService implements ProductRecognitionService {
  OpenAIProductRecognitionService({
    required this.apiKey,
    required this.model,
    this.endpoint = 'https://api.openai.com/v1/responses',
    http.Client? client,
    this.matcher = const ProductMatcher(),
    this.timeout = const Duration(seconds: 60),
  }) : client = client ?? http.Client();

  final String apiKey;
  final String model;
  final String endpoint;
  final http.Client client;
  final ProductMatcher matcher;
  final Duration timeout;

  static const _instructions = '''
You analyze salon inventory photos for product logging.
Analyze the entire image from edge to edge, not only the center of the frame.
Identify only products that are clearly visible in the image.
Use the supplied catalogue to match products by visible brand, product line, package type, and shade code.
Use a catalogue product id only when the visual evidence supports it.
If a visible product is not in the catalogue, still identify it from the image, infer the best brand/category/package fields you can, set matchedProductId to null, and set matchStatus to unmatched.
Estimate a normalized bounding box for every detected physical product using left, top, width, and height values from 0 to 1.
Count visible units or packages. Do not invent products outside the image.
If text, shade, or packaging is unclear, keep the best visual description, lower confidence, and add a warning.
Return an empty detectedProducts list if there are no identifiable salon products.
''';

  static const _responseFormat = {
    'type': 'json_schema',
    'name': 'salon_scan_analysis',
    'strict': true,
    'schema': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['scanQuality', 'warnings', 'detectedProducts'],
      'properties': {
        'scanQuality': {
          'type': 'string',
          'enum': ['good', 'fair', 'poor', 'unknown'],
        },
        'warnings': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'detectedProducts': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': [
              'temporaryId',
              'detectedName',
              'matchedProductId',
              'brand',
              'category',
              'packagingType',
              'shadeCode',
              'quantity',
              'recognitionConfidence',
              'catalogueMatchConfidence',
              'notes',
              'matchStatus',
              'warnings',
              'normalizedBoundingBox',
              'cameraCropPath',
            ],
            'properties': {
              'temporaryId': {'type': 'string'},
              'detectedName': {'type': 'string'},
              'matchedProductId': {
                'type': ['string', 'null'],
              },
              'brand': {'type': 'string'},
              'category': {'type': 'string'},
              'packagingType': {'type': 'string'},
              'shadeCode': {'type': 'string'},
              'quantity': {'type': 'integer'},
              'recognitionConfidence': {'type': 'number'},
              'catalogueMatchConfidence': {'type': 'number'},
              'notes': {'type': 'string'},
              'matchStatus': {
                'type': 'string',
                'enum': ['matched', 'needs_review', 'unmatched'],
              },
              'warnings': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'normalizedBoundingBox': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['left', 'top', 'width', 'height'],
                'properties': {
                  'left': {'type': 'number'},
                  'top': {'type': 'number'},
                  'width': {'type': 'number'},
                  'height': {'type': 'number'},
                },
              },
              'cameraCropPath': {
                'type': ['string', 'null'],
              },
            },
          },
        },
      },
    },
  };

  @override
  Future<ScanAnalysisResult> analyzeImage({
    required File image,
    required List<SalonProduct> catalogue,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const AnalysisException(
          'OpenAI API key is required when mock mode is disabled.');
    }

    try {
      final imageBytes = await image.readAsBytes();
      final payload = {
        'model': model,
        'instructions': _instructions,
        'store': false,
        'input': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text':
                    'Catalogue JSON:\n${_catalogueJson(catalogue)}\n\nAnalyze the attached camera image and return the structured inventory scan result.',
              },
              {
                'type': 'input_image',
                'image_url':
                    'data:${_mimeType(image.path)};base64,${base64Encode(imageBytes)}',
                'detail': 'high',
              },
            ],
          },
        ],
        'text': {
          'format': _responseFormat,
        },
      };

      final response = await client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AnalysisException(
            'OpenAI analysis failed with status ${response.statusCode}: ${response.body}');
      }

      final outputText = _extractTextOutput(response.body);
      final analysis = ScanAnalysisResult.fromAiResponse(outputText);
      return matcher.refineAnalysis(analysis, catalogue);
    } on AnalysisException {
      rethrow;
    } on SocketException catch (error) {
      throw AnalysisException('Could not reach OpenAI for image analysis.',
          cause: error);
    } on TimeoutException catch (error) {
      throw AnalysisException('OpenAI image analysis timed out.', cause: error);
    } catch (error) {
      throw AnalysisException('OpenAI image analysis failed.', cause: error);
    }
  }

  String _catalogueJson(List<SalonProduct> catalogue) {
    return jsonEncode(
      catalogue.map((product) {
        return {
          'id': product.id,
          'name': product.name,
          'brand': product.brand,
          'category': product.category,
          'packagingType': product.packagingType,
          'formFactor': product.displayFormFactor,
          'sizeLabel': product.sizeLabel,
          'shadeCode': product.shadeCode,
          'aliases': product.aliases,
          'sku': product.sku,
          if (product.barcode != null) 'barcode': product.barcode,
          'recognitionStatus': product.recognitionStatus.label,
        };
      }).toList(),
    );
  }

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _extractTextOutput(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded.containsKey('scanQuality')) {
      return jsonEncode(decoded);
    }
    if (decoded is! Map) {
      throw const AnalysisException('OpenAI response was not a JSON object.');
    }

    final error = decoded['error'];
    if (error is Map && error['message'] is String) {
      throw AnalysisException(error['message'].toString());
    }

    final outputText = decoded['output_text'];
    if (outputText is String && outputText.trim().isNotEmpty) {
      return outputText;
    }

    final output = decoded['output'];
    if (output is List) {
      final parts = <String>[];
      for (final item in output) {
        if (item is! Map) {
          continue;
        }
        final contentText = _extractContentText(item['content']);
        if (contentText != null) {
          parts.add(contentText);
        }
      }
      final joined = parts.join('\n').trim();
      if (joined.isNotEmpty) {
        return joined;
      }
    }

    final contentText = _extractContentText(decoded['content']);
    if (contentText != null && contentText.trim().isNotEmpty) {
      return contentText;
    }

    throw const AnalysisException(
        'OpenAI response did not include analysis text.');
  }

  String? _extractContentText(Object? content) {
    if (content is String) {
      return content;
    }
    if (content is! List) {
      return null;
    }
    final parts = <String>[];
    for (final item in content) {
      if (item is! Map) {
        continue;
      }
      if (item['type'] == 'refusal') {
        throw AnalysisException(
            item['refusal']?.toString() ?? 'OpenAI refused the image.');
      }
      final parsed = item['parsed'];
      if (parsed is Map && parsed.containsKey('scanQuality')) {
        parts.add(jsonEncode(parsed));
        continue;
      }
      final text = item['text'];
      if (text is String && text.trim().isNotEmpty) {
        parts.add(text);
      }
    }
    final joined = parts.join('\n').trim();
    return joined.isEmpty ? null : joined;
  }
}
