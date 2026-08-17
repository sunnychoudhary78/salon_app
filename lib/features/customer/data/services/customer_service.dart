import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/location/selected_location.dart';
import 'package:saloon_booking/core/location/selected_location_provider.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/providers/audience_mode_provider.dart';
import 'package:saloon_booking/features/customer/data/providers/salon_browse_filters_provider.dart';

class CustomerService {
  CustomerService(this._dio);

  final Dio _dio;

  Future<List<BannerModel>> getBanners() async {
    final response = await _dio.get('${AppConfig.appPrefix}/banners');
    return parseDataList(response.data, BannerModel.fromJson);
  }

  Future<BrowseSalonsResult> browseSalons({
    String? search,
    String? city,
    String? audience,
    bool featured = false,
    bool hasDiscount = false,
    bool hasAvailableSlots = false,
    int limit = 20,
    int offset = 0,
    double? userLat,
    double? userLng,
    double? minRating,
    double? maxDistanceKm,
  }) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/salons',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (city != null && city.isNotEmpty) 'city': city,
        if (audience != null && audience.isNotEmpty) 'audience': audience,
        if (featured) 'featured': true,
        if (hasDiscount) 'has_discount': true,
        if (hasAvailableSlots) 'has_available_slots': true,
        if (userLat != null && userLng != null) ...{
          'user_lat': userLat,
          'user_lng': userLng,
        },
        if (minRating != null) 'min_rating': minRating,
        if (maxDistanceKm != null) 'max_distance_km': maxDistanceKm,
        'limit': limit,
        'offset': offset,
      },
    );
    return BrowseSalonsResult.fromJson(
      response.data as Map<String, dynamic>,
      SalonModel.fromJson,
    );
  }

  Future<SalonModel> getSalon(
    String id, {
    double? userLat,
    double? userLng,
  }) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/salons/$id',
      queryParameters: {
        if (userLat != null && userLng != null) ...{
          'user_lat': userLat,
          'user_lng': userLng,
        },
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return SalonModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> addFavorite(String salonId) async {
    await _dio.post(
      '${AppConfig.appPrefix}/favorites',
      data: {'salon_id': salonId},
    );
  }

  Future<void> removeFavorite(String salonId) async {
    await _dio.delete('${AppConfig.appPrefix}/favorites/$salonId');
  }

  Future<List<SalonModel>> getFavoriteSalons({
    double? userLat,
    double? userLng,
  }) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/favorites',
      queryParameters: {
        if (userLat != null && userLng != null) ...{
          'user_lat': userLat,
          'user_lng': userLng,
        },
      },
    );
    return parseDataList(response.data, SalonModel.fromJson);
  }

  Future<SalonSlotsResponse> fetchSalonSlots(
    String salonId,
    String date,
  ) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/salons/$salonId/slots',
      queryParameters: {'date': date},
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return SalonSlotsResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<PremiumConfigModel> fetchPremiumConfig() async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/premium-booking/config',
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return PremiumConfigModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<BookingModel>> createBookings({
    required String salonId,
    required List<String> serviceIds,
    required String bookingDate,
    required String bookingTime,
    String? notes,
    String? staffId,
    bool isPremium = false,
    String? mergeIntoGroupId,
  }) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/bookings',
      data: {
        'salon_id': salonId,
        'service_ids': serviceIds,
        'booking_date': bookingDate,
        'booking_time': bookingTime,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (staffId != null && staffId.isNotEmpty) 'staff_id': staffId,
        if (isPremium) 'is_premium': true,
        if (mergeIntoGroupId != null && mergeIntoGroupId.isNotEmpty)
          'merge_into_group_id': mergeIntoGroupId,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data is List) {
      return data
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [BookingModel.fromJson(data as Map<String, dynamic>)];
  }

  Future<List<BookingModel>> getMyBookings() async {
    final response = await _dio.get('${AppConfig.appPrefix}/bookings');
    return CrashReporting.measure(
      'customer_bookings_parse',
      () => parseDataList(response.data, BookingModel.fromJson),
    );
  }

  Future<BookingModel> cancelBooking(String id) async {
    final response = await _dio.patch(
      '${AppConfig.appPrefix}/bookings/$id/cancel',
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return BookingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ReviewModel> createReview({
    required String bookingId,
    required int rating,
    int? staffRating,
    String? review,
  }) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/reviews',
      data: {
        'booking_id': bookingId,
        'rating': rating,
        if (staffRating != null) 'staff_rating': staffRating,
        if (review != null && review.isNotEmpty) 'review': review,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return ReviewModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SalonReviewsResult> getSalonReviews(
    String salonId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/salons/$salonId/reviews',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final body = response.data as Map<String, dynamic>;
    final meta = body['meta'] as Map<String, dynamic>? ?? {};
    final reviews = (body['data'] as List<dynamic>? ?? [])
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return SalonReviewsResult(
      reviews: reviews,
      total: meta['total'] as int? ?? reviews.length,
      limit: meta['limit'] as int? ?? limit,
      offset: meta['offset'] as int? ?? offset,
    );
  }

  Future<CouponModel?> validateCoupon(String code) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/coupons/validate',
      data: {'code': code},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['valid'] == true && data['coupon'] != null) {
      return CouponModel.fromJson(data['coupon'] as Map<String, dynamic>);
    }
    return null;
  }
}

final customerServiceProvider = Provider<CustomerService>((ref) {
  ref.keepAlive();
  return CustomerService(ref.watch(dioProvider));
});

class CustomerShellTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final customerShellTabIndexProvider =
    NotifierProvider<CustomerShellTabIndex, int>(CustomerShellTabIndex.new);

class SalonLocationContext {
  const SalonLocationContext({this.userLat, this.userLng, this.city});

  final double? userLat;
  final double? userLng;
  final String? city;
}

SalonLocationContext _readSalonLocationContext(Ref ref) {
  ref.watch(settledSalonLocationKeyProvider);
  final selected = ref.read(selectedLocationProvider).location;
  if (!selected.isSet) return const SalonLocationContext();
  if (selected.source == LocationSource.manualCity) {
    return SalonLocationContext(city: selected.city);
  }
  return SalonLocationContext(
    userLat: selected.latitude,
    userLng: selected.longitude,
  );
}

/// When false (user is searching), for-you rail skips network fetches.
final homeForYouEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    salonBrowseFiltersProvider.select((filters) => filters.search.isEmpty),
  );
});

final bannersProvider = FutureProvider.autoDispose<List<BannerModel>>((ref) {
  return ref.watch(customerServiceProvider).getBanners();
});

bool _salonHasDeal(SalonModel salon) =>
    salon.hasDiscount || salon.discountedServicesCount > 0;

int _forYouSortTier(SalonModel salon) {
  final featured = salon.isFeatured;
  final discounted = _salonHasDeal(salon);
  if (featured && discounted) return 0;
  if (featured) return 1;
  if (discounted) return 2;
  return 3;
}

SalonModel _mergeSalonEntry(SalonModel primary, SalonModel secondary) {
  return SalonModel(
    id: primary.id,
    salonName: primary.salonName,
    salonType: primary.salonType,
    description: primary.description ?? secondary.description,
    address: primary.address ?? secondary.address,
    formattedAddress: primary.formattedAddress ?? secondary.formattedAddress,
    locality: primary.locality ?? secondary.locality,
    city: primary.city ?? secondary.city,
    state: primary.state ?? secondary.state,
    postalCode: primary.postalCode ?? secondary.postalCode,
    coverImage: primary.coverImage ?? secondary.coverImage,
    galleryImages: primary.galleryImages.isNotEmpty
        ? primary.galleryImages
        : secondary.galleryImages,
    previewImages: primary.previewImages.isNotEmpty
        ? primary.previewImages
        : secondary.previewImages,
    phone: primary.phone ?? secondary.phone,
    openingTime: primary.openingTime ?? secondary.openingTime,
    closingTime: primary.closingTime ?? secondary.closingTime,
    status: primary.status ?? secondary.status,
    isActive: primary.isActive && secondary.isActive,
    services: primary.services.isNotEmpty
        ? primary.services
        : secondary.services,
    slotsToday: primary.slotsToday ?? secondary.slotsToday,
    isFeatured: primary.isFeatured || secondary.isFeatured,
    hasDiscount: primary.hasDiscount || secondary.hasDiscount,
    discountedServicesCount:
        primary.discountedServicesCount > secondary.discountedServicesCount
        ? primary.discountedServicesCount
        : secondary.discountedServicesCount,
    maxSavingsPercent: primary.maxSavingsPercent > secondary.maxSavingsPercent
        ? primary.maxSavingsPercent
        : secondary.maxSavingsPercent,
    hasServices: primary.hasServices || secondary.hasServices,
    averageRating: primary.averageRating ?? secondary.averageRating,
    reviewCount: primary.reviewCount > secondary.reviewCount
        ? primary.reviewCount
        : secondary.reviewCount,
    latitude: primary.latitude ?? secondary.latitude,
    longitude: primary.longitude ?? secondary.longitude,
    distanceKm: primary.distanceKm ?? secondary.distanceKm,
    isFavorite: primary.isFavorite || secondary.isFavorite,
  );
}

List<SalonModel> _mergeForYouSalons(
  List<SalonModel> featured,
  List<SalonModel> discounted,
) {
  final featuredOrder = <String, int>{
    for (var i = 0; i < featured.length; i++) featured[i].id: i,
  };
  final map = <String, SalonModel>{};

  for (final salon in featured) {
    map[salon.id] = salon;
  }
  for (final salon in discounted) {
    final existing = map[salon.id];
    map[salon.id] = existing != null
        ? _mergeSalonEntry(existing, salon)
        : salon;
  }

  final merged = map.values.toList();
  merged.sort((a, b) {
    final tierCompare = _forYouSortTier(a).compareTo(_forYouSortTier(b));
    if (tierCompare != 0) return tierCompare;
    final aIdx = featuredOrder[a.id] ?? 999;
    final bIdx = featuredOrder[b.id] ?? 999;
    if (aIdx != bIdx) return aIdx.compareTo(bIdx);
    return a.salonName.compareTo(b.salonName);
  });
  return merged;
}

final favoriteSalonsProvider = FutureProvider.autoDispose<List<SalonModel>>((
  ref,
) async {
  final locationKey = ref.watch(settledSalonLocationKeyProvider);
  if (locationKey.isEmpty) return [];

  final ctx = _readSalonLocationContext(ref);
  return ref
      .read(customerServiceProvider)
      .getFavoriteSalons(userLat: ctx.userLat, userLng: ctx.userLng);
});

final forYouSalonsProvider = FutureProvider.autoDispose<List<SalonModel>>((
  ref,
) async {
  if (!ref.watch(homeForYouEnabledProvider)) return [];

  final locationKey = ref.watch(settledSalonLocationKeyProvider);
  if (locationKey.isEmpty) return [];

  final audience = ref.watch(audienceModeValueProvider).apiValue;
  final filters = ref.watch(salonBrowseFiltersProvider);
  final ctx = _readSalonLocationContext(ref);
  final service = ref.read(customerServiceProvider);
  final results = await Future.wait([
    for (final request in forYouBrowseRequests(filters))
      service.browseSalons(
        featured: request.featured,
        hasDiscount: request.hasDiscount,
        audience: audience,
        limit: 8,
        city: ctx.city,
        userLat: ctx.userLat,
        userLng: ctx.userLng,
        minRating: request.minRating,
        maxDistanceKm: request.maxDistanceKm,
        hasAvailableSlots: request.hasAvailableSlots,
      ),
  ]);
  return _mergeForYouSalons(results[0].salons, results[1].salons);
});

class PaginatedSalonsState {
  const PaginatedSalonsState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<SalonModel> items;
  final bool hasMore;
  final bool isLoadingMore;

  PaginatedSalonsState copyWith({
    List<SalonModel>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) => PaginatedSalonsState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class PaginatedSalonsNotifier extends AsyncNotifier<PaginatedSalonsState> {
  static const _pageSize = 10;
  int _reloadGeneration = 0;
  bool _reloadFrameScheduled = false;

  Future<BrowseSalonsResult> _fetchPage(int offset) {
    final ctx = _readSalonLocationContext(ref);
    final filters = ref.read(salonBrowseFiltersProvider);
    final audience = ref.read(audienceModeValueProvider).apiValue;
    final sheet = filters.sheetQuery;
    return ref
        .read(customerServiceProvider)
        .browseSalons(
          limit: _pageSize,
          offset: offset,
          search: filters.search.isEmpty ? null : filters.search,
          city: ctx.city,
          audience: audience,
          userLat: ctx.userLat,
          userLng: ctx.userLng,
          minRating: sheet.minRating,
          maxDistanceKm: sheet.maxDistanceKm,
          hasAvailableSlots: sheet.hasAvailableSlots,
        );
  }

  Future<PaginatedSalonsState> _loadFirstPage() async {
    final locationKey = ref.read(settledSalonLocationKeyProvider);
    if (locationKey.isEmpty) {
      return const PaginatedSalonsState(items: [], hasMore: true);
    }

    final page = await _fetchPage(0);
    return PaginatedSalonsState(items: page.salons, hasMore: page.hasMore);
  }

  @override
  Future<PaginatedSalonsState> build() async {
    ref.keepAlive();

    // Coalesce rapid dependency changes (e.g. hammering Men/Women) into one
    // post-frame reload so we never mutate state mid-build.
    void scheduleReload() {
      _reloadGeneration++;
      if (_reloadFrameScheduled) return;
      _reloadFrameScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _reloadFrameScheduled = false;
        if (!ref.mounted) return;
        final generationAtStart = _reloadGeneration;
        unawaited(
          reload().whenComplete(() {
            // Another toggle landed while this fetch was in flight.
            if (ref.mounted && generationAtStart != _reloadGeneration) {
              scheduleReload();
            }
          }),
        );
      });
    }

    ref.listen(salonBrowseFiltersProvider, (previous, next) {
      if (previous != next) scheduleReload();
    });
    ref.listen(settledSalonLocationKeyProvider, (previous, next) {
      if (previous != next) scheduleReload();
    });
    ref.listen(audienceModeValueProvider, (previous, next) {
      if (previous != next) scheduleReload();
    });

    return _loadFirstPage();
  }

  /// Refreshes page 1 while keeping existing items visible when possible.
  Future<void> reload() async {
    final previous = state.value;
    final locationKey = ref.read(settledSalonLocationKeyProvider);
    if (locationKey.isEmpty) {
      state = const AsyncData(PaginatedSalonsState(items: [], hasMore: true));
      return;
    }

    try {
      final page = await _fetchPage(0);
      state = AsyncData(
        PaginatedSalonsState(items: page.salons, hasMore: page.hasMore),
      );
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _fetchPage(current.items.length);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.salons],
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final paginatedSalonsProvider =
    AsyncNotifierProvider<PaginatedSalonsNotifier, PaginatedSalonsState>(
      PaginatedSalonsNotifier.new,
    );

final salonDetailProvider = FutureProvider.autoDispose
    .family<SalonModel, String>((ref, salonId) {
      final ctx = _readSalonLocationContext(ref);
      return ref
          .watch(customerServiceProvider)
          .getSalon(salonId, userLat: ctx.userLat, userLng: ctx.userLng);
    });

const _similarSalonRadiusKm = 25.0;
const _similarSalonLimit = 8;

final similarSalonsProvider = FutureProvider.autoDispose
    .family<List<SalonModel>, String>((ref, salonId) async {
      final salon = await ref.watch(salonDetailProvider(salonId).future);
      final lat = salon.latitude;
      final lng = salon.longitude;
      if (lat == null || lng == null) return const [];

      final audience = ref.watch(audienceModeValueProvider).apiValue;
      final result = await ref
          .read(customerServiceProvider)
          .browseSalons(
            audience: audience,
            userLat: lat,
            userLng: lng,
            maxDistanceKm: _similarSalonRadiusKm,
            limit: _similarSalonLimit + 1,
          );

      return result.salons
          .where((item) => item.id != salonId)
          .take(_similarSalonLimit)
          .toList();
    });

class SalonFavoriteNotifier extends Notifier<bool> {
  SalonFavoriteNotifier(this.salonId);

  final String salonId;

  @override
  bool build() {
    ref.listen(salonDetailProvider(salonId), (previous, next) {
      final nextValue = next.value?.isFavorite;
      if (nextValue != null) state = nextValue;
    });
    return ref.read(salonDetailProvider(salonId)).value?.isFavorite ?? false;
  }

  Future<void> toggle() async {
    final current = state;
    state = !current;
    try {
      final api = ref.read(customerServiceProvider);
      if (current) {
        await api.removeFavorite(salonId);
      } else {
        await api.addFavorite(salonId);
      }
      ref.invalidate(favoriteSalonsProvider);
    } catch (_) {
      state = current;
      rethrow;
    }
  }
}

final salonFavoriteProvider =
    NotifierProvider.autoDispose.family<SalonFavoriteNotifier, bool, String>(
      SalonFavoriteNotifier.new,
    );

final salonReviewsProvider = FutureProvider.autoDispose
    .family<SalonReviewsResult, String>((ref, salonId) {
      return ref.watch(customerServiceProvider).getSalonReviews(salonId);
    });

typedef SalonSlotsKey = ({String salonId, String date});

final salonSlotsProvider = FutureProvider.autoDispose
    .family<SalonSlotsResponse, SalonSlotsKey>((ref, key) {
      return ref
          .watch(customerServiceProvider)
          .fetchSalonSlots(key.salonId, key.date);
    });

final premiumConfigProvider = FutureProvider.autoDispose<PremiumConfigModel>((
  ref,
) {
  return ref.watch(customerServiceProvider).fetchPremiumConfig();
});

final myBookingsProvider = FutureProvider.autoDispose<List<BookingModel>>((
  ref,
) {
  return ref.watch(customerServiceProvider).getMyBookings();
});

class BookingActions extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    ref.keepAlive();
  }

  Future<List<BookingModel>> create({
    required String salonId,
    required List<String> serviceIds,
    required String bookingDate,
    required String bookingTime,
    String? notes,
    String? staffId,
    bool isPremium = false,
    String? mergeIntoGroupId,
  }) async {
    state = const AsyncLoading();
    late List<BookingModel> bookings;
    final result = await AsyncValue.guard(() async {
      bookings = await ref
          .read(customerServiceProvider)
          .createBookings(
            salonId: salonId,
            serviceIds: serviceIds,
            bookingDate: bookingDate,
            bookingTime: bookingTime,
            notes: notes,
            staffId: staffId,
            isPremium: isPremium,
            mergeIntoGroupId: mergeIntoGroupId,
          );
    });
    state = result;
    ref.invalidate(myBookingsProvider);
    // A new booking changes slot availability, so refresh slot data too.
    ref.invalidate(salonSlotsProvider);
    if (result.hasError) {
      throw result.error!;
    }
    return bookings;
  }

  Future<void> cancel(String bookingId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(customerServiceProvider).cancelBooking(bookingId),
    );
    ref.invalidate(myBookingsProvider);
    // Cancelling frees the slot, so refresh slot availability.
    ref.invalidate(salonSlotsProvider);
    if (state.hasError) throw state.error!;
  }
}

final bookingActionsProvider = AsyncNotifierProvider<BookingActions, void>(
  BookingActions.new,
);

class ReviewActions extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    ref.keepAlive();
  }

  Future<String?> submit({
    required String bookingId,
    required int rating,
    int? staffRating,
    String? review,
    String? salonId,
  }) async {
    state = const AsyncLoading();
    var resolvedSalonId = salonId;
    state = await AsyncValue.guard(() async {
      await ref
          .read(customerServiceProvider)
          .createReview(
            bookingId: bookingId,
            rating: rating,
            staffRating: staffRating,
            review: review,
          );
      if (resolvedSalonId == null) {
        final bookings = await ref
            .read(customerServiceProvider)
            .getMyBookings();
        for (final booking in bookings) {
          if (booking.id == bookingId) {
            resolvedSalonId = booking.salon?.id;
            break;
          }
        }
      }
    });
    ref.invalidate(myBookingsProvider);
    if (resolvedSalonId != null) {
      ref.invalidate(salonReviewsProvider(resolvedSalonId!));
      ref.invalidate(salonDetailProvider(resolvedSalonId!));
      ref.invalidate(paginatedSalonsProvider);
      ref.invalidate(forYouSalonsProvider);
    }
    if (state.hasError) throw state.error!;
    await ref.read(myBookingsProvider.future);
    return resolvedSalonId;
  }
}

final reviewActionsProvider = AsyncNotifierProvider<ReviewActions, void>(
  ReviewActions.new,
);

final validateCouponProvider = FutureProvider.autoDispose
    .family<CouponModel?, String>((ref, code) {
      if (code.isEmpty) return Future.value(null);
      return ref.watch(customerServiceProvider).validateCoupon(code);
    });
