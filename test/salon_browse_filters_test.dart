import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/features/customer/data/providers/salon_browse_filters_provider.dart';

void main() {
  group('SalonBrowseFilters', () {
    test('defaults to a 5 km radius', () {
      const filters = SalonBrowseFilters();

      expect(filters.maxDistanceKm, kDefaultSalonRadiusKm);
      expect(filters.hasActiveFilters, isFalse);
      expect(filters.hasCustomDistanceFilter, isFalse);
    });

    test('treats a wider radius as an active filter', () {
      const filters = SalonBrowseFilters(maxDistanceKm: 10);

      expect(filters.hasActiveFilters, isTrue);
      expect(filters.hasCustomDistanceFilter, isTrue);
    });

    test('treats Any distance as an active filter', () {
      const filters = SalonBrowseFilters(maxDistanceKm: null);

      expect(filters.hasActiveFilters, isTrue);
      expect(filters.hasCustomDistanceFilter, isTrue);
    });

    test('clearFilters restores the 5 km default and keeps search', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(salonBrowseFiltersProvider.notifier);

      notifier.applyFilters(
        minRating: 4,
        maxDistanceKm: 25,
        hasAvailableSlots: true,
      );
      notifier.setSearch('cut');
      notifier.clearFilters();

      final filters = container.read(salonBrowseFiltersProvider);
      expect(filters.search, 'cut');
      expect(filters.minRating, isNull);
      expect(filters.maxDistanceKm, kDefaultSalonRadiusKm);
      expect(filters.hasAvailableSlots, isFalse);
      expect(filters.hasActiveFilters, isFalse);
    });

    test('sheetQuery exposes rating, distance, and open-today', () {
      const filters = SalonBrowseFilters(
        minRating: 4.5,
        maxDistanceKm: 10,
        hasAvailableSlots: true,
      );

      expect(filters.sheetQuery.minRating, 4.5);
      expect(filters.sheetQuery.maxDistanceKm, 10);
      expect(filters.sheetQuery.hasAvailableSlots, isTrue);
    });

    test('For you browse args include rating and open-today filters', () {
      const filters = SalonBrowseFilters(
        minRating: 4.5,
        maxDistanceKm: 10,
        hasAvailableSlots: true,
      );

      final requests = forYouBrowseRequests(filters);
      expect(requests, hasLength(2));
      expect(requests[0].featured, isTrue);
      expect(requests[0].hasDiscount, isFalse);
      expect(requests[1].featured, isFalse);
      expect(requests[1].hasDiscount, isTrue);
      for (final request in requests) {
        expect(request.minRating, 4.5);
        expect(request.maxDistanceKm, 10);
        expect(request.hasAvailableSlots, isTrue);
      }
    });
  });
}
