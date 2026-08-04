import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalonBrowseFilters {
  const SalonBrowseFilters({
    this.search = '',
    this.minRating,
    this.maxDistanceKm,
    this.hasAvailableSlots = false,
  });

  final String search;
  final double? minRating;
  final double? maxDistanceKm;
  final bool hasAvailableSlots;

  bool get hasActiveFilters =>
      minRating != null || maxDistanceKm != null || hasAvailableSlots;

  bool get hasSearchOrFilters => search.isNotEmpty || hasActiveFilters;

  SalonBrowseFilters copyWith({
    String? search,
    double? minRating,
    double? maxDistanceKm,
    bool? hasAvailableSlots,
    bool clearMinRating = false,
    bool clearMaxDistanceKm = false,
  }) {
    return SalonBrowseFilters(
      search: search ?? this.search,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      maxDistanceKm: clearMaxDistanceKm
          ? null
          : (maxDistanceKm ?? this.maxDistanceKm),
      hasAvailableSlots: hasAvailableSlots ?? this.hasAvailableSlots,
    );
  }
}

class SalonBrowseFiltersNotifier extends Notifier<SalonBrowseFilters> {
  @override
  SalonBrowseFilters build() => const SalonBrowseFilters();

  void setSearch(String query) {
    state = state.copyWith(search: query.trim());
  }

  void toggleAvailableSlots() {
    state = state.copyWith(hasAvailableSlots: !state.hasAvailableSlots);
  }

  void setHasAvailableSlots(bool value) {
    state = state.copyWith(hasAvailableSlots: value);
  }

  void applyFilters({
    double? minRating,
    double? maxDistanceKm,
    bool? hasAvailableSlots,
  }) {
    state = state.copyWith(
      minRating: minRating,
      maxDistanceKm: maxDistanceKm,
      hasAvailableSlots: hasAvailableSlots ?? state.hasAvailableSlots,
      clearMinRating: minRating == null,
      clearMaxDistanceKm: maxDistanceKm == null,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      clearMinRating: true,
      clearMaxDistanceKm: true,
      hasAvailableSlots: false,
    );
  }
}

final salonBrowseFiltersProvider =
    NotifierProvider<SalonBrowseFiltersNotifier, SalonBrowseFilters>(
      SalonBrowseFiltersNotifier.new,
    );
