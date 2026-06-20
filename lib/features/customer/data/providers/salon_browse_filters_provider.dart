import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalonBrowseFilters {
  const SalonBrowseFilters({
    this.search = '',
    this.minRating,
    this.maxDistanceKm,
  });

  final String search;
  final double? minRating;
  final double? maxDistanceKm;

  bool get hasActiveFilters => minRating != null || maxDistanceKm != null;

  bool get hasSearchOrFilters => search.isNotEmpty || hasActiveFilters;

  SalonBrowseFilters copyWith({
    String? search,
    double? minRating,
    double? maxDistanceKm,
    bool clearMinRating = false,
    bool clearMaxDistanceKm = false,
  }) {
    return SalonBrowseFilters(
      search: search ?? this.search,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      maxDistanceKm:
          clearMaxDistanceKm ? null : (maxDistanceKm ?? this.maxDistanceKm),
    );
  }
}

class SalonBrowseFiltersNotifier extends Notifier<SalonBrowseFilters> {
  @override
  SalonBrowseFilters build() => const SalonBrowseFilters();

  void setSearch(String query) {
    state = state.copyWith(search: query.trim());
  }

  void applyFilters({double? minRating, double? maxDistanceKm}) {
    state = state.copyWith(
      minRating: minRating,
      maxDistanceKm: maxDistanceKm,
      clearMinRating: minRating == null,
      clearMaxDistanceKm: maxDistanceKm == null,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      clearMinRating: true,
      clearMaxDistanceKm: true,
    );
  }
}

final salonBrowseFiltersProvider =
    NotifierProvider<SalonBrowseFiltersNotifier, SalonBrowseFilters>(
  SalonBrowseFiltersNotifier.new,
);
