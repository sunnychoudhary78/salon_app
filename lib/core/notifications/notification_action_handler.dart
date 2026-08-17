import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/notifications/local_notification_service.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';

const bookingAcceptActionId = 'booking_accept';
const bookingRejectActionId = 'booking_reject';
const bookingRequestCategoryId = 'BOOKING_REQUEST';

/// Handles Accept/Reject from notification actions in any isolate.
Future<void> handleNotificationAction(NotificationResponse response) async {
  final actionId = response.actionId;
  if (actionId != bookingAcceptActionId && actionId != bookingRejectActionId) {
    return;
  }

  final rawPayload = response.payload;
  if (rawPayload == null || rawPayload.isEmpty) return;

  NotificationPayload payload;
  try {
    payload = NotificationPayload.fromData(
      jsonDecode(rawPayload) as Map<String, dynamic>,
    );
  } catch (_) {
    return;
  }

  final bookingId = payload.bookingId;
  if (bookingId == null || bookingId.isEmpty) return;

  final accepted = actionId == bookingAcceptActionId;
  final result = await _respondToBooking(
    bookingId: bookingId,
    accept: accepted,
  );

  final local = LocalNotificationService();
  await local.initialize(onTap: (_) {}, forBackgroundAction: true);
  await local.cancelByPayload(payload);
  await local.showActionResult(
    success: result.success,
    title: accepted ? 'Booking accepted' : 'Booking rejected',
    body: result.message,
  );
}

Future<({bool success, String message})> _respondToBooking({
  required String bookingId,
  required bool accept,
}) async {
  try {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final token = await storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      return (
        success: false,
        message: 'Please open CATCHY and sign in to respond.',
      );
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'x-client-type': 'mobile',
        },
      ),
    );

    final path = accept
        ? '${AppConfig.appPrefix}/owner/bookings/$bookingId/accept'
        : '${AppConfig.appPrefix}/owner/bookings/$bookingId/reject';

    await dio.patch(path, data: accept ? null : <String, dynamic>{});
    return (
      success: true,
      message: accept
          ? 'The booking was accepted.'
          : 'The booking was rejected.',
    );
  } on DioException catch (e) {
    final serverMessage = e.response?.data is Map
        ? (e.response!.data['message']?.toString())
        : null;
    debugPrint('[notification_action] ${e.message}');
    return (
      success: false,
      message:
          serverMessage ??
          (e.type == DioExceptionType.connectionError
              ? 'No network. Open the app and try again.'
              : 'Could not update booking. Open the app and try again.'),
    );
  } catch (e) {
    debugPrint('[notification_action] $e');
    return (
      success: false,
      message: 'Could not update booking. Open the app and try again.',
    );
  }
}

bool get supportsMobilePush =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);
