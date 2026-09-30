import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/features/beautyassistant/data/models/beauty_chat_models.dart';
import 'package:saloon_booking/features/beautyassistant/data/services/beauty_assistant_service.dart';

final beautyAssistantServiceProvider = Provider<BeautyAssistantService>(
  (ref) => BeautyAssistantService(),
);

final beautyAssistantProvider =
    NotifierProvider<BeautyAssistantNotifier, BeautyConversationState>(
      BeautyAssistantNotifier.new,
    );

class BeautyAssistantNotifier extends Notifier<BeautyConversationState> {
  @override
  BeautyConversationState build() => const BeautyConversationState();

  Future<void> sendMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || state.isLoading) return;

    final userMessage = BeautyChatMessage(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      text: message,
      role: BeautyMessageRole.user,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
      lastUserMessage: message,
    );
    await _requestResponse(message);
  }

  Future<void> retry() async {
    final message = state.lastUserMessage;
    if (message == null || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    await _requestResponse(message);
  }

  Future<void> _requestResponse(String message) async {
    try {
      final response = await ref
          .read(beautyAssistantServiceProvider)
          .sendMessage(message);
      state = state.copyWith(
        messages: [
          ...state.messages,
          BeautyChatMessage(
            id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
            text: response.message,
            role: BeautyMessageRole.assistant,
            createdAt: DateTime.now(),
            recommendations: response.recommendations,
          ),
        ],
        isLoading: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'We couldn’t get a response. Please try again.',
      );
    }
  }
}
