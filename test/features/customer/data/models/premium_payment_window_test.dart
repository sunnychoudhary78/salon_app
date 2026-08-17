import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/shared/widgets/premium_countdown.dart';

BookingModel _booking({
  String status = 'ACCEPTED',
  String type = 'PREMIUM',
  String paymentStatus = 'PENDING',
  DateTime? dueAt,
}) {
  return BookingModel(
    id: 'b1',
    bookingStatus: status,
    bookingDate: '2099-01-01',
    bookingTime: '10:00:00',
    bookingType: type,
    premiumPaymentStatus: paymentStatus,
    premiumPaymentDueAt: dueAt,
  );
}

void main() {
  group('PremiumConfigModel', () {
    test('parses payment_window_minutes', () {
      final config = PremiumConfigModel.fromJson({
        'enabled': true,
        'fee': 199,
        'currency': 'INR',
        'payment_window_minutes': 20,
      });
      expect(config.paymentWindowMinutes, 20);
    });

    test('defaults and clamps the payment window', () {
      expect(
        PremiumConfigModel.fromJson({'fee': 199}).paymentWindowMinutes,
        15,
      );
      expect(
        PremiumConfigModel.fromJson({
          'fee': 199,
          'payment_window_minutes': 999,
        }).paymentWindowMinutes,
        120,
      );
    });
  });

  group('BookingModel premium window', () {
    test('needsPremiumPayment while due_at is in the future', () {
      final booking = _booking(
        dueAt: DateTime.now().add(const Duration(minutes: 10)),
      );
      expect(booking.needsPremiumPayment, isTrue);
      expect(booking.premiumPaymentExpired, isFalse);
    });

    test('premiumPaymentExpired after due_at', () {
      final booking = _booking(
        dueAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(booking.needsPremiumPayment, isFalse);
      expect(booking.premiumPaymentExpired, isTrue);
    });

    test('legacy accepted premium without due_at can still pay', () {
      final booking = _booking();
      expect(booking.needsPremiumPayment, isTrue);
      expect(booking.premiumPaymentExpired, isFalse);
    });

    test('paid premium is neither due nor expired', () {
      final booking = _booking(
        paymentStatus: 'PAID',
        dueAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(booking.needsPremiumPayment, isFalse);
      expect(booking.premiumPaymentExpired, isFalse);
    });
  });

  group('OwnerBookingModel premium window', () {
    test('parses due_at and exposes the same helpers', () {
      final dueAt = DateTime.now().add(const Duration(minutes: 5));
      final booking = OwnerBookingModel.fromJson({
        'id': 'o1',
        'booking_status': 'ACCEPTED',
        'booking_date': '2099-01-01',
        'booking_time': '10:00:00',
        'booking_type': 'PREMIUM',
        'premium_payment_status': 'PENDING',
        'premium_payment_due_at': dueAt.toUtc().toIso8601String(),
      });
      expect(booking.needsPremiumPayment, isTrue);
      expect(booking.premiumPaymentExpired, isFalse);
      expect(booking.premiumPaymentDueAt, isNotNull);
    });
  });

  group('remainingLabel', () {
    test('shows unpaid copy when there is no deadline', () {
      expect(
        remainingLabel(null),
        'Pay now to confirm this premium booking',
      );
    });

    test('shows expired copy after due_at', () {
      expect(
        remainingLabel(DateTime.now().subtract(const Duration(seconds: 2))),
        'Premium payment window expired',
      );
    });
  });
}
