import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/location/selected_location.dart';
import 'package:saloon_booking/core/location/selected_location_provider.dart';
import 'package:saloon_booking/core/location/user_location_service.dart';

void main() {
  const current = SelectedLocation(
    displayLabel: 'Current location',
    source: LocationSource.gps,
    latitude: 28.6139,
    longitude: 77.2090,
  );

  test('ignores insignificant GPS movement for salon queries', () {
    const nearby = UserLocation(latitude: 28.6140, longitude: 77.2091);

    expect(isSignificantGpsChange(current, nearby), isFalse);
  });

  test('accepts meaningful GPS movement for salon queries', () {
    const moved = UserLocation(latitude: 28.6200, longitude: 77.2090);

    expect(isSignificantGpsChange(current, moved), isTrue);
  });

  test('treats a recent last-known fix as fresh', () {
    final now = DateTime(2026, 8, 11, 18);
    expect(
      UserLocationService.isFreshLastKnown(
        now.subtract(const Duration(minutes: 4)),
        now: now,
      ),
      isTrue,
    );
  });

  test('treats an old last-known fix as stale', () {
    final now = DateTime(2026, 8, 11, 18);
    expect(
      UserLocationService.isFreshLastKnown(
        now.subtract(const Duration(minutes: 6)),
        now: now,
      ),
      isFalse,
    );
  });
}
