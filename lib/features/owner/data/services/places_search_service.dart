import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/owner/data/models/place_suggestion.dart';

class PlacesSearchService {
  PlacesSearchService(this._dio);

  final Dio _dio;

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];

    final response = await _dio.get(
      '${AppConfig.appPrefix}/places/search',
      queryParameters: {'q': q, 'limit': 5},
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data is! List) return [];

    return data
        .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
        .where((p) => p.label.isNotEmpty)
        .toList();
  }
}

final placesSearchServiceProvider = Provider<PlacesSearchService>((ref) {
  return PlacesSearchService(ref.watch(dioProvider));
});
