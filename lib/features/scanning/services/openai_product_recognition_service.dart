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
You are the product recognition engine for a live store inventory scanner.
Analyze the entire camera image from edge to edge. Do not limit recognition to the center of the frame or the visible scanner chrome.

Primary goal:
- Identify real retail/product identity, not generic object descriptions.
- First read visible package text, logos, brand marks, product names, variants, shade codes, sizes, and labels.
- Camera frames may come from mirrored webcams. If label text appears reversed, mentally unmirror it and use the corrected brand/product name.
- If the product is a real package with partially readable brand/product text, return the best supported identity with lower confidence and a warning instead of returning an empty list.
- detectedName must be the most specific product display name supported by the image, for example "Coca-Cola Classic", "The Ordinary Hyaluronic Acid 2% + B5", or "Professional Colour Cream 5N".
- Do not use generic names like "red can", "white dropper bottle", "box", "tube", or "bottle" as products. If the label or brand is not readable enough to identify a product, do not return that item unless there is strong distinctive packaging evidence and add a warning.
- If the best available description is only color, shape, material, or packaging, for example "blue and white container", "plastic tube", or "white bottle", return no detected product for that object.
- Only return items that appear to be existing commercial products with a readable or strongly recognizable brand/product identity.

Catalogue matching:
- The supplied catalogue is optional reference data, not the full universe of valid products.
- Use a catalogue product id only when visible brand, product line, packaging, shade/variant, or barcode evidence supports it.
- If a visible product is not in the catalogue, still identify it from the image, set matchedProductId to null, set matchStatus to unmatched, and fill brand/category/packagingType from the label and packaging.
- Never force an unmatched grocery, beverage, skincare, cosmetic, or household product into the salon catalogue.

Multiple products and quantity:
- Group identical visible units into one detectedProducts entry and set quantity to the visible count.
- Count partially occluded matching units when enough of the label, silhouette, cap, colorway, or repeated packaging is visible to support that they are the same product.
- Example: two Coca-Cola bottles on a table, one partly behind the other, should return one Coca-Cola entry with quantity 2.
- Return separate entries for different brands, products, variants, sizes, shades, or packaging types.
- Do not invent hidden products outside the image.

Bounding boxes and uncertainty:
- Estimate normalizedBoundingBox with left, top, width, and height values from 0 to 1. For grouped identical products, cover the visible group.
- Keep recognitionConfidence high only when the brand/product text or distinctive packaging is clear.
- If text, variant, size, or quantity is uncertain, lower confidence and add a specific warning.
- Return an empty detectedProducts list if no product identity is readable or strongly recognizable.
''';

  static const _responseFormat = {
    'type': 'json_schema',
    'name': 'inventory_scan_analysis',
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
                    'Optional catalogue JSON:\n${_catalogueJson(catalogue)}\n\nAnalyze the attached camera image and return only the structured inventory scan result. Prioritize readable brand and product text over generic object descriptions.',
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
