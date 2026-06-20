import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  const UserLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class UserLocationService {
  Future<UserLocation?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    ).timeout(timeout, onTimeout: () => throw TimeoutException('Location timeout'));

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<String> resolveLabel(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return 'Current location';
      final place = placemarks.first;
      final locality = place.subLocality?.trim();
      final subAdmin = place.locality?.trim();
      final city = place.administrativeArea?.trim();
      final parts = <String>[
        if (locality != null && locality.isNotEmpty) locality,
        if (subAdmin != null &&
            subAdmin.isNotEmpty &&
            subAdmin != locality)
          subAdmin,
        if (city != null &&
            city.isNotEmpty &&
            city != subAdmin &&
            city != locality)
          city,
      ];
      if (parts.isNotEmpty) return parts.take(2).join(', ');
      if (place.name != null && place.name!.trim().isNotEmpty) {
        return place.name!.trim();
      }
      return 'Current location';
    } catch (_) {
      return 'Current location';
    }
  }
}
