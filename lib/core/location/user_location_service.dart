import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  const UserLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum LocationFetchFailure {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  unknown,
}

class LocationEnsureResult {
  const LocationEnsureResult({required this.ready, this.failure});

  final bool ready;
  final LocationFetchFailure? failure;
}

class UserLocationService {
  static const Duration _permissionTimeout = Duration(seconds: 5);
  static const Duration _locationTimeout = Duration(seconds: 10);

  Future<LocationEnsureResult> ensureServiceAndPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationEnsureResult(
          ready: false,
          failure: LocationFetchFailure.permissionDenied,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return const LocationEnsureResult(
          ready: false,
          failure: LocationFetchFailure.permissionDeniedForever,
        );
      }

      // Re-check after permission — user may have just granted access.
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        try {
          // May prompt the user to enable location services.
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
            ),
          );
        } catch (_) {
          // Re-check: user may have enabled location during the prompt.
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            return const LocationEnsureResult(
              ready: false,
              failure: LocationFetchFailure.serviceDisabled,
            );
          }
        }
      }

      try {
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        ).timeout(_permissionTimeout);
      } catch (_) {
        // Warmup failure is non-fatal; caller retries getCurrentLocation.
      }

      // Final service check before reporting ready.
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationEnsureResult(
          ready: false,
          failure: LocationFetchFailure.serviceDisabled,
        );
      }

      return const LocationEnsureResult(ready: true);
    } catch (_) {
      return const LocationEnsureResult(
        ready: false,
        failure: LocationFetchFailure.unknown,
      );
    }
  }

  Future<UserLocation?> getCurrentLocation({
    Duration timeout = _locationTimeout,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: timeout,
            ),
          ).timeout(
            timeout,
            onTimeout: () => throw TimeoutException('Location timeout'),
          );

      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> resolveLabel(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 8));
      if (placemarks.isEmpty) return 'Current location';
      final place = placemarks.first;
      final locality = place.subLocality?.trim();
      final subAdmin = place.locality?.trim();
      final city = place.administrativeArea?.trim();
      final parts = <String>[
        if (locality != null && locality.isNotEmpty) locality,
        if (subAdmin != null && subAdmin.isNotEmpty && subAdmin != locality)
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

String locationFailureMessage(LocationFetchFailure? failure) {
  switch (failure) {
    case LocationFetchFailure.permissionDenied:
      return 'Location permission is off. Enable it in settings or pick a city.';
    case LocationFetchFailure.permissionDeniedForever:
      return 'Location permission is blocked. Open settings to allow access.';
    case LocationFetchFailure.serviceDisabled:
      return 'Turn on device location (GPS) to continue.';
    case LocationFetchFailure.timeout:
      return 'Location timed out. Try again or pick a city.';
    case LocationFetchFailure.unknown:
    case null:
      return 'Could not get your location. Try again or pick a city.';
  }
}
