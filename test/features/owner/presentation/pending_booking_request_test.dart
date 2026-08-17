import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/presentation/providers/pending_booking_request.dart';

OwnerBookingModel _booking({
  required String id,
  String? groupId,
  String bookingType = 'STANDARD',
  double? premiumAmount,
  String? serviceName,
}) {
  return OwnerBookingModel(
    id: id,
    bookingStatus: 'PENDING',
    bookingDate: '2026-08-13',
    bookingTime: '10:00:00',
    groupId: groupId,
    bookingType: bookingType,
    premiumAmount: premiumAmount,
    serviceName: serviceName,
  );
}

void main() {
  group('ownerGroupIsPremium', () {
    test('is true when any sibling row is PREMIUM', () {
      final group = [
        _booking(id: 'std', groupId: 'g1', serviceName: 'Spa'),
        _booking(
          id: 'prem',
          groupId: 'g1',
          bookingType: 'PREMIUM',
          premiumAmount: 199,
          serviceName: 'Haircut',
        ),
      ];
      expect(ownerGroupIsPremium(group), isTrue);
      expect(ownerGroupPremiumAmount(group), 199);
    });

    test('is false for a standard-only group', () {
      final group = [_booking(id: 'a'), _booking(id: 'b', groupId: 'g2')];
      expect(ownerGroupIsPremium(group), isFalse);
      expect(ownerGroupPremiumAmount(group), isNull);
    });
  });

  test('pending queue marks a mixed group as premium', () {
    final queue = buildPendingBookingQueue([
      _booking(id: 'std', groupId: 'g1', serviceName: 'Spa'),
      _booking(
        id: 'prem',
        groupId: 'g1',
        bookingType: 'PREMIUM',
        premiumAmount: 150,
        serviceName: 'Haircut',
      ),
    ]);

    expect(queue, hasLength(1));
    expect(queue.single.isPremium, isTrue);
    expect(queue.single.amount, 150);
  });

  test('pending queue leaves a standard request unmarked', () {
    final queue = buildPendingBookingQueue([
      _booking(id: 'a', groupId: 'g1', serviceName: 'Trim'),
    ]);
    expect(queue.single.isPremium, isFalse);
  });
}
