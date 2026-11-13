import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/location/selected_location_provider.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/features/ai_stylist/data/models/ai_stylist_models.dart';
import 'package:saloon_booking/features/ai_stylist/data/repositories/ai_stylist_repository.dart';
import 'package:saloon_booking/features/customer/data/providers/audience_mode_provider.dart';

class AiStylistChatState {
  const AiStylistChatState({
    this.sessions = const [],
    this.activeSession,
    this.messages = const [],
    this.isLoadingSessions = false,
    this.isLoadingMessages = false,
    this.isAnalyzing = false,
    this.isSendingChat = false,
    this.uploadProgress = 0.0,
    this.errorMessage,
  });

  final List<AiStylistSession> sessions;
  final AiStylistSession? activeSession;
  final List<AiChatMessage> messages;
  final bool isLoadingSessions;
  final bool isLoadingMessages;
  final bool isAnalyzing;
  final bool isSendingChat;
  final double uploadProgress;
  final String? errorMessage;

  AiStylistChatState copyWith({
    List<AiStylistSession>? sessions,
    AiStylistSession? activeSession,
    List<AiChatMessage>? messages,
    bool? isLoadingSessions,
    bool? isLoadingMessages,
    bool? isAnalyzing,
    bool? isSendingChat,
    double? uploadProgress,
    String? errorMessage,
    bool clearActiveSession = false,
    bool clearError = false,
  }) {
    return AiStylistChatState(
      sessions: sessions ?? this.sessions,
      activeSession:
          clearActiveSession ? null : (activeSession ?? this.activeSession),
      messages: messages ?? this.messages,
      isLoadingSessions: isLoadingSessions ?? this.isLoadingSessions,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isSendingChat: isSendingChat ?? this.isSendingChat,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AiStylistNotifier extends Notifier<AiStylistChatState> {
  @override
  AiStylistChatState build() {
    Future.microtask(initialize);
    return const AiStylistChatState(isLoadingSessions: true);
  }

  AiStylistRepository get _repo => ref.read(aiStylistRepositoryProvider);

  ({double? lat, double? lng}) _coords() {
    final loc = ref.read(selectedLocationProvider).location;
    return (lat: loc.latitude, lng: loc.longitude);
  }

  String _audience() => ref.read(audienceModeValueProvider).apiValue;

  Future<void> initialize() async {
    state = state.copyWith(isLoadingSessions: true, clearError: true);
    try {
      final sessions = await _repo.listSessions();
      if (!ref.mounted) return;
      if (sessions.isNotEmpty) {
        state = state.copyWith(sessions: sessions, isLoadingSessions: false);
        await selectSession(sessions.first.id);
      } else {
        final created = await _repo.createSession();
        if (!ref.mounted) return;
        state = state.copyWith(
          sessions: [created],
          activeSession: created,
          messages: const [],
          isLoadingSessions: false,
        );
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingSessions: false,
        errorMessage: userFacingErrorMessage(e),
      );
    }
  }

  Future<AiStylistSession> ensureActiveSession() async {
    if (state.activeSession != null) return state.activeSession!;
    final created = await _repo.createSession();
    state = state.copyWith(
      sessions: [created, ...state.sessions],
      activeSession: created,
      messages: const [],
    );
    return created;
  }

  Future<void> startNewSession() async {
    state = state.copyWith(isLoadingMessages: true, clearError: true);
    try {
      final created = await _repo.createSession();
      if (!ref.mounted) return;
      state = state.copyWith(
        sessions: [created, ...state.sessions],
        activeSession: created,
        messages: const [],
        isLoadingMessages: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingMessages: false,
        errorMessage: userFacingErrorMessage(e),
      );
    }
  }

  Future<void> selectSession(String sessionId) async {
    state = state.copyWith(isLoadingMessages: true, clearError: true);
    try {
      final res = await _repo.getSessionMessages(sessionId);
      if (!ref.mounted) return;
      state = state.copyWith(
        activeSession: res.session,
        messages: res.messages,
        isLoadingMessages: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingMessages: false,
        errorMessage: userFacingErrorMessage(e),
      );
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _repo.deleteSession(sessionId);
      if (!ref.mounted) return;
      final remaining =
          state.sessions.where((s) => s.id != sessionId).toList();
      state = state.copyWith(sessions: remaining);
      if (state.activeSession?.id == sessionId) {
        if (remaining.isNotEmpty) {
          await selectSession(remaining.first.id);
        } else {
          await startNewSession();
        }
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: userFacingErrorMessage(e));
    }
  }

  Future<bool> analyzeMultiAngleScan({
    required String frontImagePath,
    String? leftImagePath,
    String? rightImagePath,
    required Map<String, dynamic> onDeviceFeatures,
    required AiStylistPreferences preferences,
    String? userNote,
  }) async {
    state = state.copyWith(
      isAnalyzing: true,
      uploadProgress: 0.0,
      clearError: true,
    );
    try {
      final session = await ensureActiveSession();
      final coords = _coords();
      await _repo.analyzeFaceAndSuggest(
        sessionId: session.id,
        frontImagePath: frontImagePath,
        leftImagePath: leftImagePath,
        rightImagePath: rightImagePath,
        onDeviceFeatures: onDeviceFeatures,
        preferences: preferences,
        userNote: userNote,
        userLat: coords.lat,
        userLng: coords.lng,
        audience: preferences.gender,
        onSendProgress: (sent, total) {
          if (total > 0 && ref.mounted) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );
      if (!ref.mounted) return false;
      final refreshed = await _repo.getSessionMessages(session.id);
      final sessions = await _repo.listSessions();
      if (!ref.mounted) return false;
      state = state.copyWith(
        sessions: sessions,
        activeSession: refreshed.session,
        messages: refreshed.messages,
        isAnalyzing: false,
        uploadProgress: 1.0,
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: userFacingErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || state.isSendingChat) return;

    state = state.copyWith(isSendingChat: true, clearError: true);
    final optimisticId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticUserMsg = AiChatMessage(
      id: optimisticId,
      sessionId: state.activeSession?.id ?? '',
      role: 'user',
      contentText: clean,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, optimisticUserMsg]);

    try {
      final session = await ensureActiveSession();
      final coords = _coords();
      final assistantMsg = await _repo.sendChatMessage(
        sessionId: session.id,
        message: clean,
        analysisId: session.activeAnalysisId,
        userLat: coords.lat,
        userLng: coords.lng,
        audience: _audience(),
      );
      if (!ref.mounted) return;
      final sessions = await _repo.listSessions();
      if (!ref.mounted) return;
      state = state.copyWith(
        sessions: sessions,
        messages: [...state.messages, assistantMsg],
        isSendingChat: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        messages:
            state.messages.where((m) => m.id != optimisticId).toList(),
        isSendingChat: false,
        errorMessage: userFacingErrorMessage(e),
      );
    }
  }

  Future<AiTryOnResult> generateTryOn({
    required String analysisId,
    required HairstyleRecommendation recommendation,
    String? hairColor,
  }) {
    return _repo.generateTryOn(
      analysisId: analysisId,
      hairstyleName: recommendation.name,
      hairstylePrompt: recommendation.tryonPrompt,
      hairColor: hairColor,
    );
  }
}

final aiStylistProvider =
    NotifierProvider<AiStylistNotifier, AiStylistChatState>(
  AiStylistNotifier.new,
);
