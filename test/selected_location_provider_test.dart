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
}
