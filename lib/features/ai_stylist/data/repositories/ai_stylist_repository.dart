import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/ai_stylist/data/models/ai_stylist_models.dart';

class AiStylistRepository {
  AiStylistRepository(this._dio);

  final Dio _dio;

  String get _base => '${AppConfig.appPrefix}/ai-stylist';

  Future<AiStylistSession> createSession({String? title}) async {
    final response = await _dio.post(
      '$_base/sessions',
      data: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      },
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return AiStylistSession.fromJson(data);
  }

  Future<List<AiStylistSession>> listSessions({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '$_base/sessions',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final raw = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AiStylistSession.fromJson)
        .toList();
  }

  Future<({AiStylistSession session, List<AiChatMessage> messages})>
      getSessionMessages(String sessionId) async {
    final response = await _dio.get('$_base/sessions/$sessionId/messages');
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final session = AiStylistSession.fromJson(
      data['session'] as Map<String, dynamic>,
    );
    final messagesRaw = data['messages'] as List<dynamic>? ?? [];
    final messages = messagesRaw
        .whereType<Map<String, dynamic>>()
        .map(AiChatMessage.fromJson)
        .toList();
    return (session: session, messages: messages);
  }

  Future<void> deleteSession(String sessionId) async {
    await _dio.delete('$_base/sessions/$sessionId');
  }

  Future<({AiStylistSession session, AiChatMessage assistantMessage})>
      analyzeFaceAndSuggest({
    required String sessionId,
    required String frontImagePath,
    String? leftImagePath,
    String? rightImagePath,
    required Map<String, dynamic> onDeviceFeatures,
    required AiStylistPreferences preferences,
    String? userNote,
    double? userLat,
    double? userLng,
    String? audience,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formMap = <String, dynamic>{
      'front': await MultipartFile.fromFile(
        frontImagePath,
        filename: 'front.jpg',
      ),
      if (leftImagePath != null && leftImagePath.isNotEmpty)
        'left': await MultipartFile.fromFile(
          leftImagePath,
          filename: 'left.jpg',
        ),
      if (rightImagePath != null && rightImagePath.isNotEmpty)
        'right': await MultipartFile.fromFile(
          rightImagePath,
          filename: 'right.jpg',
        ),
      'on_device_features': jsonEncode(onDeviceFeatures),
      'preferences': jsonEncode(preferences.toJson()),
      if (userNote != null && userNote.trim().isNotEmpty)
        'user_note': userNote.trim(),
      if (userLat != null && userLng != null) ...{
        'user_lat': userLat,
        'user_lng': userLng,
      },
      if (audience != null && audience.isNotEmpty) 'audience': audience,
    };

    final response = await _dio.post(
      '$_base/sessions/$sessionId/analyze',
      data: FormData.fromMap(formMap),
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 90),
      ),
      onSendProgress: onSendProgress,
    );

    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final session = AiStylistSession.fromJson(
      data['session'] as Map<String, dynamic>,
    );
    final message = AiChatMessage.fromJson(
      data['message'] as Map<String, dynamic>,
    );
    return (session: session, assistantMessage: message);
  }

  Future<AiChatMessage> sendChatMessage({
    required String sessionId,
    required String message,
    String? analysisId,
    double? userLat,
    double? userLng,
    String? audience,
    String? language,
  }) async {
    final response = await _dio.post(
      '$_base/sessions/$sessionId/chat',
      data: {
        'message': message,
        if (analysisId != null && analysisId.isNotEmpty)
          'analysis_id': analysisId,
        if (userLat != null && userLng != null) ...{
          'user_lat': userLat,
          'user_lng': userLng,
        },
        if (audience != null && audience.isNotEmpty) 'audience': audience,
        if (language != null && language.isNotEmpty) 'language': language,
      },
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return AiChatMessage.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<List<RecommendedSalonItem>> getRecommendedSalons({
    required String analysisId,
    String? hairstyleTag,
    double? userLat,
    double? userLng,
    String? audience,
  }) async {
    final response = await _dio.get(
      '$_base/analyses/$analysisId/salons',
      queryParameters: {
        if (hairstyleTag != null && hairstyleTag.isNotEmpty)
          'hairstyle_tag': hairstyleTag,
        if (userLat != null && userLng != null) ...{
          'user_lat': userLat,
          'user_lng': userLng,
        },
        if (audience != null && audience.isNotEmpty) 'audience': audience,
      },
    );
    final raw = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(RecommendedSalonItem.fromJson)
        .toList();
  }

  Future<AiTryOnResult> generateTryOn({
    required String analysisId,
    required String hairstyleName,
    String? hairstylePrompt,
    String? hairColor,
  }) async {
    final response = await _dio.post(
      '$_base/analyses/$analysisId/try-on',
      data: {
        'hairstyle_name': hairstyleName,
        if (hairstylePrompt != null && hairstylePrompt.isNotEmpty)
          'hairstyle_prompt': hairstylePrompt,
        if (hairColor != null && hairColor.isNotEmpty) 'hair_color': hairColor,
      },
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    final data = (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    return AiTryOnResult.fromJson(data);
  }
}

final aiStylistRepositoryProvider = Provider<AiStylistRepository>((ref) {
  return AiStylistRepository(ref.watch(dioProvider));
});
