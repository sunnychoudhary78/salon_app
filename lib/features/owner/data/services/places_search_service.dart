import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/owner/data/models/place_suggestion.dart';
import 'package:saloon_booking/features/owner/data/models/salon_location_selection.dart';

class PlacesSearchBias {
  const PlacesSearchBias({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 50000,
  });

  final double latitude;
  final double longitude;
  final int radiusMeters;
}

class PlacesSearchService {
  PlacesSearchService(this._dio);

  final Dio _dio;

  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    String? sessionToken,
    PlacesSearchBias? bias,
    CancelToken? cancelToken,
  }) async {
    final q = query.trim();
    if (q.length < 3) return [];

    final queryParameters = <String, dynamic>{
      'q': q,
      'limit': 8,
      if (sessionToken != null && sessionToken.isNotEmpty)
        'sessiontoken': sessionToken,
      if (bias != null) ...{
        'lat': bias.latitude,
        'lng': bias.longitude,
        'radius': bias.radiusMeters,
      },
    };

    final response = await _dio.get(
      '${AppConfig.appPrefix}/places/search',
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data is! List) return [];

    return data
        .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
        .where((p) => p.label.isNotEmpty)
        .toList();
  }

  Future<PlaceSuggestion?> fetchPlaceDetails(
    String placeId, {
    String? sessionToken,
    CancelToken? cancelToken,
  }) async {
    final id = placeId.trim();
    if (id.isEmpty) return null;

    final response = await _dio.get(
      '${AppConfig.appPrefix}/places/details',
      queryParameters: {
        'place_id': id,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'sessiontoken': sessionToken,
      },
      cancelToken: cancelToken,
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data is! Map<String, dynamic>) return null;

    final place = PlaceSuggestion.fromJson(data);
    if (!place.hasValidCoordinates) return null;
    return place;
  }

  Future<SalonLocationSelection?> reverseGeocode(
    double latitude,
    double longitude, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/places/reverse',
      queryParameters: {'lat': latitude, 'lng': longitude},
      cancelToken: cancelToken,
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data is! Map<String, dynamic>) return null;

    final place = PlaceSuggestion.fromJson(data);
    if (!place.hasValidCoordinates) return null;
    return SalonLocationSelection.fromPlace(place).copyWith(
      latitude: latitude,
      longitude: longitude,
    );
  }
}

final placesSearchServiceProvider = Provider<PlacesSearchService>((ref) {
  return PlacesSearchService(ref.watch(dioProvider));
});
