import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig({
    required this.aiApiKey,
    required this.aiEndpoint,
    required this.aiProvider,
    required this.aiModel,
    required this.useMockAi,
    required this.demoSalonId,
  });

  final String aiApiKey;
  final String aiEndpoint;
  final String aiProvider;
  final String aiModel;
  final bool useMockAi;
  final String demoSalonId;

  bool get usesOpenAi => aiProvider.toLowerCase() == 'openai';

  bool get hasAiCredentials {
    if (usesOpenAi) {
      return aiApiKey.trim().isNotEmpty;
    }
    return aiApiKey.trim().isNotEmpty && aiEndpoint.trim().isNotEmpty;
  }

  factory AppConfig.fromEnvironment() {
    final aiApiKey = _read('AI_API_KEY');
    final aiEndpoint = _read('AI_ENDPOINT');
    final aiProvider =
        _read('AI_PROVIDER', fallback: aiEndpoint.isEmpty ? 'openai' : 'api');
    final aiModel = _read('AI_MODEL', fallback: 'gpt-4.1-mini');
    final providerNeedsEndpoint = aiProvider.toLowerCase() != 'openai';
    final useMock = _readBool('USE_MOCK_AI',
        fallback:
            aiApiKey.isEmpty || (providerNeedsEndpoint && aiEndpoint.isEmpty));
    return AppConfig(
      aiApiKey: aiApiKey,
      aiEndpoint: aiEndpoint,
      aiProvider: aiProvider,
      aiModel: aiModel,
      useMockAi: useMock,
      demoSalonId: _read('DEMO_SALON_ID', fallback: 'demo_salon'),
    );
  }

  static String _read(String key, {String fallback = ''}) {
    final dotenvValue = _readDotenvValue(key);
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      return dotenvValue;
    }
    final defineValue = switch (key) {
      'AI_API_KEY' => const String.fromEnvironment('AI_API_KEY'),
      'AI_ENDPOINT' => const String.fromEnvironment('AI_ENDPOINT'),
      'AI_PROVIDER' => const String.fromEnvironment('AI_PROVIDER'),
      'AI_MODEL' => const String.fromEnvironment('AI_MODEL'),
      'USE_MOCK_AI' => const String.fromEnvironment('USE_MOCK_AI'),
      'DEMO_SALON_ID' => const String.fromEnvironment('DEMO_SALON_ID'),
      _ => '',
    };
    return defineValue.isNotEmpty ? defineValue : fallback;
  }

  static String? _readDotenvValue(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  static bool _readBool(String key, {required bool fallback}) {
    final value = _read(key);
    if (value.trim().isEmpty) {
      return fallback;
    }
    return value.toLowerCase() == 'true';
  }
}
