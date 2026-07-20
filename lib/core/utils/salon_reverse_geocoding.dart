import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:saloon_booking/features/owner/data/models/salon_location_selection.dart';
import 'package:saloon_booking/features/owner/data/services/places_search_service.dart';

Future<SalonLocationSelection?> reverseGeocodeSalonLocation(
  double latitude,
  double longitude, {
  PlacesSearchService? placesService,
  CancelToken? cancelToken,
}) async {
  if (placesService != null) {
    try {
      final backend = await placesService.reverseGeocode(
        latitude,
        longitude,
        cancelToken: cancelToken,
      );
      if (backend != null && backend.isComplete) return backend;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      // fall through to on-device geocoder
    } catch (_) {
      // fall through to on-device geocoder
    }
  }

  try {
    final placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    ).timeout(const Duration(seconds: 8));

    if (placemarks.isEmpty) return null;

    return SalonLocationSelection.fromPlacemark(
      place: placemarks.first,
      latitude: latitude,
      longitude: longitude,
    );
  } catch (_) {
    return null;
  }
}
