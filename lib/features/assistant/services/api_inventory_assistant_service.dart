import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';
import '../../inventory/models/inventory_record.dart';
import '../../scanning/models/inventory_scan.dart';
import 'assistant_context_builder.dart';
import 'inventory_assistant_service.dart';

class APIInventoryAssistantService implements InventoryAssistantService {
  APIInventoryAssistantService({
    required this.endpoint,
    required this.apiKey,
    http.Client? client,
    this.contextBuilder = const AssistantContextBuilder(),
    this.timeout = const Duration(seconds: 25),
  }) : client = client ?? http.Client();

  final String endpoint;
  final String apiKey;
  final http.Client client;
  final AssistantContextBuilder contextBuilder;
  final Duration timeout;

  @override
  Future<String> answerQuestion({
    required String question,
    required List<InventoryRecord> inventory,
    required List<InventoryScan> scans,
  }) async {
    if (endpoint.trim().isEmpty || apiKey.trim().isEmpty) {
      throw const AnalysisException(
          'Assistant endpoint and API key are required when mock mode is disabled.');
    }

    final payload = {
      'system':
          'Answer salon inventory questions using only the structured context. Do not modify Firestore.',
      'question': question,
      'context': contextBuilder.build(inventory: inventory, scans: scans),
    };

    try {
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
            'Assistant request failed with status ${response.statusCode}: ${response.body}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['answer'] is String) {
        return decoded['answer'].toString();
      }
      if (decoded is Map && decoded['content'] is String) {
        return decoded['content'].toString();
      }
      return response.body;
    } on AnalysisException {
      rethrow;
    } on TimeoutException catch (error) {
      throw AnalysisException('Assistant request timed out.', cause: error);
    } catch (error) {
      throw AnalysisException('Assistant request failed.', cause: error);
    }
  }
}
