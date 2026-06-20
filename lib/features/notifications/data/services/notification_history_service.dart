import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/notifications/data/models/notification_model.dart';

class NotificationHistoryService {
  NotificationHistoryService(this._dio);

  final Dio _dio;

  Future<NotificationsPageResult> listNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    return NotificationsPageResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/notifications/unread-count',
    );
    return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  Future<AppNotificationModel> markRead(String id) async {
    final response = await _dio.patch(
      '${AppConfig.appPrefix}/notifications/$id/read',
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return AppNotificationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> markAllRead() async {
    await _dio.patch('${AppConfig.appPrefix}/notifications/read-all');
  }
}

final notificationHistoryServiceProvider =
    Provider<NotificationHistoryService>((ref) {
  return NotificationHistoryService(ref.watch(dioProvider));
});
