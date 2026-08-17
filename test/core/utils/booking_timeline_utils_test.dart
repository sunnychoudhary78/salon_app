import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/utils/booking_timeline_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

BookingModel _booking({
  String id = 'b1',
  required String status,
  String date = '2020-01-01',
  String time = '10:00:00',
  bool hasReview = false,
  bool canReview = false,
  bool slotEnded = false,
  int? durationMinutes = 60,
}) {
  return BookingModel(
    id: id,
    bookingStatus: status,
    bookingDate: date,
    bookingTime: time,
    hasReview: hasReview,
    canReview: canReview,
    slotEnded: slotEnded,
    service: durationMinutes == null
        ? null
        : BookingServiceRef(
            serviceName: 'Haircut',
            durationMinutes: durationMinutes,
          ),
  );
}

void main() {
  group('customerCanReview', () {
    test('uses API canReview when true', () {
      expect(
        customerCanReview(
          _booking(status: 'ACCEPTED', canReview: true, date: '2099-01-01'),
        ),
        isTrue,
      );
    });

    test('COMPLETED without API flags is reviewable', () {
      expect(
        customerCanReview(_booking(status: 'COMPLETED')),
        isTrue,
      );
    });

    test('ACCEPTED with slotEnded flag is reviewable', () {
      expect(
        customerCanReview(_booking(status: 'ACCEPTED', slotEnded: true)),
        isTrue,
      );
    });

    test('ACCEPTED with ended local slot is reviewable when flags missing', () {
      expect(
        customerCanReview(
          _booking(status: 'ACCEPTED', date: '2020-06-01', time: '09:00:00'),
        ),
        isTrue,
      );
    });

    test('ACCEPTED future slot is not reviewable', () {
      expect(
        customerCanReview(
          _booking(status: 'ACCEPTED', date: '2099-06-01', time: '09:00:00'),
        ),
        isFalse,
      );
    });

    test('CANCELLED is not reviewable', () {
      expect(customerCanReview(_booking(status: 'CANCELLED')), isFalse);
    });

    test('existing review blocks rating', () {
      expect(
        customerCanReview(
          _booking(status: 'COMPLETED', hasReview: true, canReview: true),
        ),
        isFalse,
      );
    });
  });

  group('customerVisitCanReview', () {
    test('shows Rate when no sibling has a review and one is reviewable', () {
      final group = [
        _booking(id: 'a', status: 'COMPLETED', canReview: true),
        _booking(id: 'b', status: 'COMPLETED', canReview: true),
      ];
      expect(customerVisitHasReview(group), isFalse);
      expect(customerVisitCanReview(group), isTrue);
      expect(customerVisitReviewBooking(group)?.id, 'a');
    });

    test('hides Rate when one sibling is already reviewed', () {
      final group = [
        _booking(id: 'a', status: 'COMPLETED', hasReview: true),
        _booking(id: 'b', status: 'COMPLETED', canReview: true),
      ];
      expect(customerVisitHasReview(group), isTrue);
      expect(customerVisitCanReview(group), isFalse);
      expect(customerVisitReviewBooking(group), isNull);
    });

    test('single reviewed booking is not rateable', () {
      final group = [
        _booking(status: 'COMPLETED', hasReview: true, canReview: true),
      ];
      expect(customerVisitCanReview(group), isFalse);
    });
  });
}
