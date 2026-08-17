import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/notifications/notification_payload.dart';
import 'package:saloon_booking/core/notifications/notification_types.dart';

void main() {
  test('parses urgent booking fields and builds display body', () {
    final payload = NotificationPayload.fromData({
      'type': NotificationTypes.newBooking,
      'screen': 'owner_booking_details',
      'userRole': 'salon_owner',
      'bookingId': 'b1',
      'title': 'New Booking Request',
      'body': 'Riya · Haircut · 2026-08-10 14:30 · ₹499',
      'customerName': 'Riya',
      'serviceName': 'Haircut',
      'bookingDate': '2026-08-10',
      'bookingTime': '14:30',
      'amount': '499',
      'actions': 'accept,reject',
      'channelId': 'catchy_urgent_bookings_v5',
    });

    expect(payload.isUrgentBooking, isTrue);
    expect(payload.hasAcceptRejectActions, isTrue);
    expect(payload.isPremium, isFalse);
    expect(payload.displayBody, contains('Riya'));
    expect(payload.toDataMap()['actions'], 'accept,reject');
  });

  test('parses isPremium from FCM string data', () {
    final payload = NotificationPayload.fromData({
      'type': NotificationTypes.newBooking,
      'screen': 'owner_booking_details',
      'userRole': 'salon_owner',
      'title': 'Urgent booking request',
      'isPremium': 'true',
    });

    expect(payload.isPremium, isTrue);
    expect(payload.toDataMap()['isPremium'], 'true');
    expect(payload.isUrgentBooking, isTrue);
  });
}
