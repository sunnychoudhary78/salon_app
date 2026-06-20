import 'package:geocoding/geocoding.dart';
import 'package:saloon_booking/core/location/user_location_service.dart';

class SalonCoordinates {
  const SalonCoordinates({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}

Future<SalonCoordinates?> geocodeSalonAddress({
  required String address,
  required String city,
  required String state,
}) async {
  var query = '$address, $city, $state'.trim();
  if (query.replaceAll(',', '').trim().isEmpty) return null;
  if (!query.toLowerCase().contains('india')) {
    query = '$query, India';
  }

  try {
    final locations = await locationFromAddress(query);
    if (locations.isEmpty) return null;

    final location = locations.first;
    final label = await resolveSalonLocationLabel(
      location.latitude,
      location.longitude,
    );
    return SalonCoordinates(
      latitude: location.latitude,
      longitude: location.longitude,
      label: label,
    );
  } catch (_) {
    return null;
  }
}

Future<String> resolveSalonLocationLabel(double latitude, double longitude) async {
  final service = UserLocationService();
  final label = await service.resolveLabel(latitude, longitude);
  if (label != 'Current location') return label;
  return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
}

String formatCoordinatesLabel(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
}
