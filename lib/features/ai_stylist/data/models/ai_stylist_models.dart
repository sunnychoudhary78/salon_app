enum FaceAngleType {
  front('front', 'Front (Straight)'),
  left('left', 'Left Side (~45°)'),
  right('right', 'Right Side (~45°)');

  const FaceAngleType(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class OnDeviceFaceResult {
  const OnDeviceFaceResult({
    required this.angle,
    required this.faceDetected,
    required this.singleFace,
    required this.angleValid,
    required this.analysisMode,
    this.yawDeg,
    this.pitchDeg,
    this.rollDeg,
    this.estimatedFaceShape,
    this.foreheadWidthRatio,
    this.cheekboneWidthRatio,
    this.jawWidthRatio,
    this.faceLengthToWidthRatio,
    this.jawlineAngleDeg,
    this.upperThirdRatio,
    this.middleThirdRatio,
    this.lowerThirdRatio,
    this.lightingScore,
    this.dominantHairColorHex,
    this.feedbackMessage,
  });

  final FaceAngleType angle;
  final bool faceDetected;
  final bool singleFace;
  final bool angleValid;
  final String analysisMode;
  final double? yawDeg;
  final double? pitchDeg;
  final double? rollDeg;
  final String? estimatedFaceShape;
  final double? foreheadWidthRatio;
  final double? cheekboneWidthRatio;
  final double? jawWidthRatio;
  final double? faceLengthToWidthRatio;
  final double? jawlineAngleDeg;
  final double? upperThirdRatio;
  final double? middleThirdRatio;
  final double? lowerThirdRatio;
  final double? lightingScore;
  final String? dominantHairColorHex;
  final String? feedbackMessage;

  Map<String, dynamic> toJson() => {
        'angle': angle.apiValue,
        'face_detected': faceDetected,
        'single_face': singleFace,
        'angle_valid': angleValid,
        'analysis_mode': analysisMode,
        if (yawDeg != null) 'yaw_deg': yawDeg,
        if (pitchDeg != null) 'pitch_deg': pitchDeg,
        if (rollDeg != null) 'roll_deg': rollDeg,
        if (estimatedFaceShape != null)
          'estimated_face_shape': estimatedFaceShape,
        if (foreheadWidthRatio != null ||
            cheekboneWidthRatio != null ||
            jawWidthRatio != null)
          'measurements': {
            if (foreheadWidthRatio != null)
              'forehead_width_ratio': foreheadWidthRatio,
            if (cheekboneWidthRatio != null)
              'cheekbone_width_ratio': cheekboneWidthRatio,
            if (jawWidthRatio != null) 'jaw_width_ratio': jawWidthRatio,
            if (faceLengthToWidthRatio != null)
              'face_length_to_width_ratio': faceLengthToWidthRatio,
            if (jawlineAngleDeg != null) 'jawline_angle_deg': jawlineAngleDeg,
            if (upperThirdRatio != null) 'upper_third_ratio': upperThirdRatio,
            if (middleThirdRatio != null)
              'middle_third_ratio': middleThirdRatio,
            if (lowerThirdRatio != null) 'lower_third_ratio': lowerThirdRatio,
          },
        if (lightingScore != null || dominantHairColorHex != null)
          'hair_and_lighting': {
            if (lightingScore != null) 'lighting_score': lightingScore,
            if (dominantHairColorHex != null)
              'dominant_hair_color_hex': dominantHairColorHex,
          },
      };
}

class AiStylistPreferences {
  const AiStylistPreferences({
    this.gender = 'men',
    this.hairLengthGoal = 'medium',
    this.maintenanceLevel = 'medium',
    this.occasion = 'daily',
    this.beardPreference = 'stubble',
    this.language = 'english',
  });

  final String gender;
  final String hairLengthGoal;
  final String maintenanceLevel;
  final String occasion;
  final String beardPreference;
  final String language;

  AiStylistPreferences copyWith({
    String? gender,
    String? hairLengthGoal,
    String? maintenanceLevel,
    String? occasion,
    String? beardPreference,
    String? language,
  }) {
    return AiStylistPreferences(
      gender: gender ?? this.gender,
      hairLengthGoal: hairLengthGoal ?? this.hairLengthGoal,
      maintenanceLevel: maintenanceLevel ?? this.maintenanceLevel,
      occasion: occasion ?? this.occasion,
      beardPreference: beardPreference ?? this.beardPreference,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'hair_length_goal': hairLengthGoal,
        'maintenance_level': maintenanceLevel,
        'occasion': occasion,
        if (gender == 'men') 'beard_preference': beardPreference,
        'language': language,
      };
}

class HairstyleRecommendation {
  const HairstyleRecommendation({
    required this.name,
    required this.matchScore,
    required this.whyItSuits,
    required this.barberInstructions,
    required this.maintenanceLevel,
    required this.stylingTip,
    required this.beardPairing,
    required this.matchedServiceNames,
    required this.tryonPrompt,
    this.imageUrl,
  });

  final String name;
  final int matchScore;
  final String whyItSuits;
  final String barberInstructions;
  final String maintenanceLevel;
  final String stylingTip;
  final String beardPairing;
  final List<String> matchedServiceNames;
  final String tryonPrompt;
  final String? imageUrl;

  factory HairstyleRecommendation.fromJson(Map<String, dynamic> json) {
    return HairstyleRecommendation(
      name: json['name']?.toString() ?? 'Recommended Cut',
      matchScore: (json['match_score'] as num?)?.toInt() ?? 88,
      whyItSuits: json['why_it_suits']?.toString() ?? '',
      barberInstructions: json['barber_instructions']?.toString() ?? '',
      maintenanceLevel: json['maintenance_level']?.toString() ?? 'Medium',
      stylingTip: json['styling_tip']?.toString() ?? '',
      beardPairing: json['beard_pairing']?.toString() ?? '',
      matchedServiceNames: (json['matched_service_names'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      tryonPrompt: json['tryon_prompt']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['preview_image_url']?.toString(),
    );
  }
}

class FaceProfileSummary {
  const FaceProfileSummary({
    required this.faceShape,
    required this.confidence,
    this.hairType,
    this.hairDensity,
    this.skinUndertone,
    this.keyObservations = const [],
    this.avoidStyles = const [],
  });

  final String faceShape;
  final int confidence;
  final String? hairType;
  final String? hairDensity;
  final String? skinUndertone;
  final List<String> keyObservations;
  final List<String> avoidStyles;

  factory FaceProfileSummary.fromJson(Map<String, dynamic> json) {
    return FaceProfileSummary(
      faceShape: json['face_shape']?.toString() ?? 'Oval',
      confidence: (json['confidence'] as num?)?.toInt() ?? 85,
      hairType: json['hair_type']?.toString(),
      hairDensity: json['hair_density']?.toString(),
      skinUndertone: json['skin_undertone']?.toString(),
      keyObservations: (json['key_observations'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      avoidStyles: (json['avoid_styles'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class MatchedSalonService {
  const MatchedSalonService({
    required this.id,
    required this.serviceName,
    required this.price,
    this.discountPrice,
    this.durationMinutes = 30,
  });

  final String id;
  final String serviceName;
  final double price;
  final double? discountPrice;
  final int durationMinutes;

  double get effectivePrice => discountPrice ?? price;

  factory MatchedSalonService.fromJson(Map<String, dynamic> json) {
    return MatchedSalonService(
      id: json['id']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? 'Haircut',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
    );
  }
}

class RecommendedSalonItem {
  const RecommendedSalonItem({
    required this.id,
    required this.salonName,
    this.city,
    this.locality,
    this.averageRating,
    this.reviewCount = 0,
    this.distanceKm,
    this.coverImageUrl,
    this.matchedServices = const [],
  });

  final String id;
  final String salonName;
  final String? city;
  final String? locality;
  final double? averageRating;
  final int reviewCount;
  final double? distanceKm;
  final String? coverImageUrl;
  final List<MatchedSalonService> matchedServices;

  factory RecommendedSalonItem.fromJson(Map<String, dynamic> json) {
    String? cover;
    final previewImages = json['preview_images'] as List<dynamic>?;
    if (previewImages != null && previewImages.isNotEmpty) {
      final first = previewImages.first;
      if (first is Map<String, dynamic>) {
        cover = (first['medium'] ?? first['thumb'] ?? first['full'])?.toString();
      } else if (first is String) {
        cover = first;
      }
    }

    return RecommendedSalonItem(
      id: json['id']?.toString() ?? '',
      salonName: json['salon_name']?.toString() ?? 'Salon',
      city: json['city']?.toString(),
      locality: json['locality']?.toString(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      coverImageUrl: cover,
      matchedServices: (json['matched_services'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MatchedSalonService.fromJson)
          .toList(),
    );
  }
}

class AiCardPayload {
  const AiCardPayload({
    required this.type,
    this.analysisId,
    this.faceProfile,
    this.recommendations = const [],
    this.recommendedSalons = const [],
    this.quickTips = const [],
    this.followUpQuestions = const [],
  });

  final String type;
  final String? analysisId;
  final FaceProfileSummary? faceProfile;
  final List<HairstyleRecommendation> recommendations;
  final List<RecommendedSalonItem> recommendedSalons;
  final List<String> quickTips;
  final List<String> followUpQuestions;

  factory AiCardPayload.fromJson(Map<String, dynamic> json) {
    final profileJson = json['face_profile'];
    return AiCardPayload(
      type: json['type']?.toString() ?? 'chat_advice',
      analysisId: json['analysis_id']?.toString(),
      faceProfile: profileJson is Map<String, dynamic>
          ? FaceProfileSummary.fromJson(profileJson)
          : null,
      recommendations: (json['recommendations'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(HairstyleRecommendation.fromJson)
          .toList(),
      recommendedSalons: (json['recommended_salons'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RecommendedSalonItem.fromJson)
          .toList(),
      quickTips: (json['quick_tips'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      followUpQuestions: (json['follow_up_questions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.contentText,
    this.analysisId,
    this.imageUrls = const [],
    this.cardPayload,
    this.createdAt,
  });

  final String id;
  final String sessionId;
  final String role; // 'user' | 'assistant'
  final String contentText;
  final String? analysisId;
  final List<String> imageUrls;
  final AiCardPayload? cardPayload;
  final DateTime? createdAt;

  bool get isUser => role == 'user';

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    final payload = json['card_payload'];
    return AiChatMessage(
      id: json['id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'assistant',
      contentText: json['content_text']?.toString() ?? '',
      analysisId: json['analysis_id']?.toString(),
      imageUrls: (json['image_urls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      cardPayload: payload is Map<String, dynamic>
          ? AiCardPayload.fromJson(payload)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class AiStylistSession {
  const AiStylistSession({
    required this.id,
    required this.title,
    this.activeAnalysisId,
    this.updatedAt,
    this.previewFaceShape,
    this.previewImageUrl,
  });

  final String id;
  final String title;
  final String? activeAnalysisId;
  final DateTime? updatedAt;
  final String? previewFaceShape;
  final String? previewImageUrl;

  factory AiStylistSession.fromJson(Map<String, dynamic> json) {
    final analyses = json['analyses'] as List<dynamic>?;
    String? faceShape;
    String? imageUrl;
    if (analyses != null && analyses.isNotEmpty) {
      final first = analyses.first;
      if (first is Map<String, dynamic>) {
        faceShape = first['detected_face_shape']?.toString();
        imageUrl = first['front_image_url']?.toString();
      }
    }
    return AiStylistSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'New Style Consultation',
      activeAnalysisId: json['active_analysis_id']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      previewFaceShape: faceShape,
      previewImageUrl: imageUrl,
    );
  }
}

class AiTryOnResult {
  const AiTryOnResult({
    required this.id,
    required this.hairstyleName,
    required this.resultImageUrl,
    this.hairColor,
    this.provider,
  });

  final String id;
  final String hairstyleName;
  final String resultImageUrl;
  final String? hairColor;
  final String? provider;

  factory AiTryOnResult.fromJson(Map<String, dynamic> json) {
    return AiTryOnResult(
      id: json['id']?.toString() ?? '',
      hairstyleName: json['hairstyle_name']?.toString() ?? '',
      resultImageUrl: json['result_image_url']?.toString() ?? '',
      hairColor: json['hair_color']?.toString(),
      provider: json['provider']?.toString(),
    );
  }
}
