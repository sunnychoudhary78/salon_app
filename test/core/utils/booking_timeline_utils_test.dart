import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/utils/booking_timeline_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

BookingModel _booking({
  required String status,
  String date = '2020-01-01',
  String time = '10:00:00',
  bool hasReview = false,
  bool canReview = false,
  bool slotEnded = false,
  int? durationMinutes = 60,
}) {
  return BookingModel(
    id: 'b1',
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
}
