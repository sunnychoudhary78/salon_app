import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:saloon_booking/core/notifications/notification_types.dart';

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.screen,
    required this.userRole,
    this.bookingId,
    this.title,
    this.body,
    this.customerName,
    this.serviceName,
    this.bookingDate,
    this.bookingTime,
    this.amount,
    this.bookingGroupId,
    this.salonId,
    this.actions,
    this.channelId,
    this.sound,
    this.priority,
    this.isPremium = false,
  });

  final String type;
  final String screen;
  final String userRole;
  final String? bookingId;
  final String? title;
  final String? body;
  final String? customerName;
  final String? serviceName;
  final String? bookingDate;
  final String? bookingTime;
  final String? amount;
  final String? bookingGroupId;
  final String? salonId;
  final String? actions;
  final String? channelId;
  final String? sound;
  final String? priority;
  final bool isPremium;

  bool get isUrgentBooking => type == NotificationTypes.newBooking;

  bool get hasAcceptRejectActions {
    final raw = actions?.toLowerCase() ?? '';
    return isUrgentBooking ||
        (raw.contains('accept') && raw.contains('reject'));
  }

  String get displayBody {
    if (hasVisibleText(body)) return body!.trim();
    final parts = <String>[
      if (hasVisibleText(customerName)) customerName!.trim(),
      if (hasVisibleText(serviceName)) serviceName!.trim(),
      if (hasVisibleText(bookingDate) || hasVisibleText(bookingTime))
        [bookingDate, bookingTime].where((v) => hasVisibleText(v)).join(' '),
      if (hasVisibleText(amount)) '₹${amount!.trim()}',
    ];
    return parts.join(' · ');
  }

  static bool hasVisibleText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String? _firstNonEmpty(String? a, String? b) {
    if (hasVisibleText(a)) return a!.trim();
    if (hasVisibleText(b)) return b!.trim();
    return null;
  }

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    return NotificationPayload(
      type: data['type']?.toString() ?? '',
      screen: data['screen']?.toString() ?? '',
      userRole: data['userRole']?.toString() ?? '',
      bookingId: _optionalString(data['bookingId']),
      title: _optionalString(data['title']),
      body: _optionalString(data['body']),
      customerName: _optionalString(data['customerName']),
      serviceName: _optionalString(data['serviceName']),
      bookingDate: _optionalString(data['bookingDate']),
      bookingTime: _optionalString(data['bookingTime']),
      amount: _optionalString(data['amount']),
      bookingGroupId: _optionalString(data['bookingGroupId']),
      salonId: _optionalString(data['salonId']),
      actions: _optionalString(data['actions']),
      channelId: _optionalString(data['channelId']),
      sound: _optionalString(data['sound']),
      priority: _optionalString(data['priority']),
      isPremium: _parseBool(data['isPremium']),
    );
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final fromData = NotificationPayload.fromData(message.data);
    final notification = message.notification;
    return NotificationPayload(
      type: fromData.type,
      screen: fromData.screen,
      userRole: fromData.userRole,
      bookingId: fromData.bookingId,
      title: _firstNonEmpty(notification?.title, fromData.title),
      body: _firstNonEmpty(notification?.body, fromData.body),
      customerName: fromData.customerName,
      serviceName: fromData.serviceName,
      bookingDate: fromData.bookingDate,
      bookingTime: fromData.bookingTime,
      amount: fromData.amount,
      bookingGroupId: fromData.bookingGroupId,
      salonId: fromData.salonId,
      actions: fromData.actions,
      channelId: fromData.channelId,
      sound: fromData.sound,
      priority: fromData.priority,
      isPremium: fromData.isPremium,
    );
  }

  bool get hasDisplayContent =>
      hasVisibleText(title) || hasVisibleText(displayBody);

  Map<String, String> toDataMap() {
    return {
      'type': type,
      'screen': screen,
      'userRole': userRole,
      if (bookingId != null) 'bookingId': bookingId!,
      if (title != null) 'title': title!,
      if (body != null) 'body': body!,
      if (customerName != null) 'customerName': customerName!,
      if (serviceName != null) 'serviceName': serviceName!,
      if (bookingDate != null) 'bookingDate': bookingDate!,
      if (bookingTime != null) 'bookingTime': bookingTime!,
      if (amount != null) 'amount': amount!,
      if (bookingGroupId != null) 'bookingGroupId': bookingGroupId!,
      if (salonId != null) 'salonId': salonId!,
      if (actions != null) 'actions': actions!,
      if (channelId != null) 'channelId': channelId!,
      if (sound != null) 'sound': sound!,
      if (priority != null) 'priority': priority!,
      if (isPremium) 'isPremium': 'true',
    };
  }

  String encode() => jsonEncode(toDataMap());
}
