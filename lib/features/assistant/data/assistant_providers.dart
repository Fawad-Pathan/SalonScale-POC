import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_providers.dart';
import '../../assistant/models/chat_message.dart';
import '../../assistant/services/api_inventory_assistant_service.dart';
import '../../assistant/services/inventory_assistant_service.dart';
import '../../assistant/services/mock_inventory_assistant_service.dart';
import '../../inventory/data/inventory_providers.dart';

final inventoryAssistantServiceProvider =
    Provider<InventoryAssistantService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockAi || !config.hasAiCredentials || config.usesOpenAi) {
    return const MockInventoryAssistantService();
  }
  return APIInventoryAssistantService(
      endpoint: config.aiEndpoint, apiKey: config.aiApiKey);
});

final assistantChatControllerProvider =
    StateNotifierProvider<AssistantChatController, AssistantChatState>((ref) {
  return AssistantChatController(ref);
});

class AssistantChatState {
  const AssistantChatState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  AssistantChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AssistantChatController extends StateNotifier<AssistantChatState> {
  AssistantChatController(this.ref) : super(const AssistantChatState());

  final Ref ref;
  final _uuid = const Uuid();

  Future<void> send(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || state.isLoading) {
      return;
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      sender: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
        clearError: true);

    try {
      final repository = await ref.read(inventoryRepositoryProvider.future);
      final salonId = ref.read(salonIdProvider);
      final scans = await repository.getScans(salonId);
      final inventory = await repository.getInventory(salonId);
      final service = ref.read(inventoryAssistantServiceProvider);
      final answer = await service.answerQuestion(
          question: trimmed, inventory: inventory, scans: scans);
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        sender: 'assistant',
        content: answer,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}
