import 'package:flutter_riverpod/flutter_riverpod.dart';

const double kDefaultSalonRadiusKm = 5.0;

class SalonBrowseFilters {
  const SalonBrowseFilters({
    this.search = '',
    this.minRating,
    this.maxDistanceKm = kDefaultSalonRadiusKm,
    this.hasAvailableSlots = false,
  });

  final String search;
  final double? minRating;
  final double? maxDistanceKm;
  final bool hasAvailableSlots;

  bool get hasCustomDistanceFilter => maxDistanceKm != kDefaultSalonRadiusKm;

  bool get hasActiveFilters =>
      minRating != null || hasCustomDistanceFilter || hasAvailableSlots;

  bool get hasSearchOrFilters => search.isNotEmpty || hasActiveFilters;

  /// Rating, distance, and open-today — sent by both All salons and For you.
  ({double? minRating, double? maxDistanceKm, bool hasAvailableSlots})
      get sheetQuery => (
        minRating: minRating,
        maxDistanceKm: maxDistanceKm,
        hasAvailableSlots: hasAvailableSlots,
      );

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
    state = SalonBrowseFilters(search: state.search);
  }
}

final salonBrowseFiltersProvider =
    NotifierProvider<SalonBrowseFiltersNotifier, SalonBrowseFilters>(
      SalonBrowseFiltersNotifier.new,
    );

/// Featured + deals browse calls for the home For you rail.
List<({bool featured, bool hasDiscount})> get kForYouBrowseKinds => const [
      (featured: true, hasDiscount: false),
      (featured: false, hasDiscount: true),
    ];

/// Query args for each For you browseSalons call, including sheet filters.
List<
    ({
      bool featured,
      bool hasDiscount,
      double? minRating,
      double? maxDistanceKm,
      bool hasAvailableSlots,
    })> forYouBrowseRequests(SalonBrowseFilters filters) {
  final sheet = filters.sheetQuery;
  return [
    for (final kind in kForYouBrowseKinds)
      (
        featured: kind.featured,
        hasDiscount: kind.hasDiscount,
        minRating: sheet.minRating,
        maxDistanceKm: sheet.maxDistanceKm,
        hasAvailableSlots: sheet.hasAvailableSlots,
      ),
  ];
}
