enum BeautyMessageRole { user, assistant }

enum RecommendationCtaType {
  browseSalons('browse_salons'),
  openSalon('open_salon'),
  book('book'),
  none('none');

  const RecommendationCtaType(this.apiValue);
  final String apiValue;

  static RecommendationCtaType fromJson(Object? value) =>
      RecommendationCtaType.values.firstWhere(
        (type) => type.apiValue == value,
        orElse: () => RecommendationCtaType.none,
      );
}

class RecommendationCta {
  const RecommendationCta({required this.type, this.salonId, this.serviceName});

  final RecommendationCtaType type;
  final String? salonId;
  final String? serviceName;

  factory RecommendationCta.fromJson(Map<String, dynamic> json) =>
      RecommendationCta(
        type: RecommendationCtaType.fromJson(json['type']),
        salonId: json['salonId'] as String?,
        serviceName: json['serviceName'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'type': type.apiValue,
    if (salonId != null) 'salonId': salonId,
    if (serviceName != null) 'serviceName': serviceName,
  };
}

class BeautyRecommendation {
  const BeautyRecommendation({
    required this.serviceName,
    required this.description,
    required this.cta,
  });

  final String serviceName;
  final String description;
  final RecommendationCta cta;

  factory BeautyRecommendation.fromJson(Map<String, dynamic> json) =>
      BeautyRecommendation(
        serviceName: json['serviceName'] as String? ?? '',
        description: json['description'] as String? ?? '',
        cta: json['cta'] is Map<String, dynamic>
            ? RecommendationCta.fromJson(json['cta'] as Map<String, dynamic>)
            : const RecommendationCta(type: RecommendationCtaType.none),
      );

  Map<String, dynamic> toJson() => {
    'serviceName': serviceName,
    'description': description,
    'cta': cta.toJson(),
  };
}

class BeautyChatMessage {
  const BeautyChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.createdAt,
    this.recommendations = const [],
  });

  final String id;
  final String text;
  final BeautyMessageRole role;
  final DateTime createdAt;
  final List<BeautyRecommendation> recommendations;

  factory BeautyChatMessage.fromJson(Map<String, dynamic> json) =>
      BeautyChatMessage(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        role: json['role'] == 'user'
            ? BeautyMessageRole.user
            : BeautyMessageRole.assistant,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        recommendations: (json['recommendations'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BeautyRecommendation.fromJson)
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
    'recommendations': recommendations.map((item) => item.toJson()).toList(),
  };
}

class BeautyAssistantResponse {
  const BeautyAssistantResponse({
    required this.message,
    this.recommendations = const [],
  });

  final String message;
  final List<BeautyRecommendation> recommendations;

  factory BeautyAssistantResponse.fromJson(Map<String, dynamic> json) =>
      BeautyAssistantResponse(
        message: json['message'] as String? ?? '',
        recommendations: (json['recommendations'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(BeautyRecommendation.fromJson)
            .toList(growable: false),
      );
}

class BeautyConversationState {
  const BeautyConversationState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUserMessage,
  });

  final List<BeautyChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final String? lastUserMessage;

  BeautyConversationState copyWith({
    List<BeautyChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? lastUserMessage,
  }) => BeautyConversationState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    lastUserMessage: lastUserMessage ?? this.lastUserMessage,
  );
}
