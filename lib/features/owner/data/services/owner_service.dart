import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';

class OwnerService {
  OwnerService(this._dio);

  final Dio _dio;

  Future<SalonOwnerProfileModel> registerAsOwner({
    required String businessName,
    String? gstNumber,
  }) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/salon-owner/register',
      data: {
        'business_name': businessName,
        if (gstNumber != null && gstNumber.isNotEmpty) 'gst_number': gstNumber,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return SalonOwnerProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SalonApplicationModel> submitSalonApplication(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/salon-applications',
      data: body,
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return SalonApplicationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<String>> uploadSalonImages(List<XFile> files) async {
    final formData = FormData();
    for (final file in files) {
      formData.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ),
      );
    }

    final response = await _dio.post(
      '${AppConfig.appPrefix}/uploads/salon-images',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    final urls =
        (response.data as Map<String, dynamic>)['data']['urls']
            as List<dynamic>;
    return urls.map((e) => e as String).toList();
  }

  Future<String> uploadStaffImage(XFile file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    final response = await _dio.post(
      '${AppConfig.appPrefix}/uploads/staff-image',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    final data = (response.data as Map<String, dynamic>)['data'];
    return (data as Map<String, dynamic>)['url'] as String;
  }

  Future<List<SalonApplicationModel>> getSalonApplications({
    String? status,
  }) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/salon-applications',
      queryParameters: {'status': ?status},
    );
    return parseDataList(response.data, SalonApplicationModel.fromJson);
  }

  Future<SalonModel> updateSalon({
    required String salonId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.put(
      '${AppConfig.appPrefix}/owner/salons/$salonId',
      data: body,
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return SalonModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SalonApplicationModel> submitSalonDeactivateRequest({
    required String salonId,
    String? reason,
  }) async {
    return submitSalonApplication({
      'application_type': 'DEACTIVATE',
      'salon_id': salonId,
      if (reason != null && reason.isNotEmpty) 'description': reason,
    });
  }

  Future<SalonApplicationModel> submitSalonActivateRequest({
    required String salonId,
    String? reason,
  }) async {
    return submitSalonApplication({
      'application_type': 'ACTIVATE',
      'salon_id': salonId,
      if (reason != null && reason.isNotEmpty) 'description': reason,
    });
  }

  Future<List<SalonModel>> getOwnerSalons() async {
    final response = await _dio.get('${AppConfig.appPrefix}/owner/salons');
    return parseDataList(response.data, SalonModel.fromJson);
  }

  Future<PremiumConfigModel> getPremiumBookingConfig() async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/premium-booking/config',
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return PremiumConfigModel.fromJson(data as Map<String, dynamic>);
  }

  Future<double?> updatePremiumBookingFee({
    required String salonId,
    required double? fee,
  }) async {
    final response = await _dio.put(
      '${AppConfig.appPrefix}/owner/salons/$salonId/premium-booking',
      data: {'premium_booking_fee': fee},
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    final rawFee = data['premium_booking_fee'];
    if (rawFee == null) return null;
    return _parseOwnerDouble(rawFee);
  }

  double? _parseOwnerDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Future<List<ServiceModel>> getSalonServices(String salonId) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/salons/$salonId/services',
    );
    return parseDataList(response.data, ServiceModel.fromJson);
  }

  Future<List<String>> getServiceNames({String salonType = 'UNISEX'}) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/service-names',
      queryParameters: {'salon_type': salonType},
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return (data as List<dynamic>).map((e) => e.toString()).toList();
  }

  Future<void> createService({
    required String salonId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.post(
      '${AppConfig.appPrefix}/owner/salons/$salonId/services',
      data: body,
    );
  }

  Future<void> updateService({
    required String salonId,
    required String serviceId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put(
      '${AppConfig.appPrefix}/owner/salons/$salonId/services/$serviceId',
      data: body,
    );
  }

  Future<List<StaffModel>> getSalonStaff(String salonId) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/salons/$salonId/staff',
    );
    return StaffModel.sortByRating(
      parseDataList(response.data, StaffModel.fromJson),
    );
  }

  Future<void> createStaff({
    required String salonId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.post(
      '${AppConfig.appPrefix}/owner/salons/$salonId/staff',
      data: body,
    );
  }

  Future<void> updateStaff({
    required String salonId,
    required String staffId,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put(
      '${AppConfig.appPrefix}/owner/salons/$salonId/staff/$staffId',
      data: body,
    );
  }

  Future<OwnerDashboardV2Model> getDashboard({
    String? salonId,
    OwnerDashboardPeriod period = OwnerDashboardPeriod.last7Days,
  }) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/dashboard',
      queryParameters: {
        'v': 2,
        'period': period.apiValue,
        if (salonId != null && salonId.isNotEmpty) 'salon_id': salonId,
      },
    );
    return CrashReporting.measure(
      'owner_dashboard_parse',
      () =>
          OwnerDashboardV2Model.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<List<OwnerBookingModel>> getBookings({String? status}) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/bookings',
      queryParameters: {'status': ?status},
    );
    return CrashReporting.measure(
      'owner_bookings_parse',
      () => (response.data['data'] as List<dynamic>)
          .map((e) => OwnerBookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<OwnerBookingModel> acceptBooking(String id) async {
    final response = await _dio.patch(
      '${AppConfig.appPrefix}/owner/bookings/$id/accept',
    );
    return OwnerBookingModel.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<OwnerBookingModel> rejectBooking(String id, {String? reason}) async {
    final response = await _dio.patch(
      '${AppConfig.appPrefix}/owner/bookings/$id/reject',
      data: {'rejection_reason': ?reason},
    );
    return OwnerBookingModel.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<OwnerBookingModel> completeBooking(
    String id, {
    double? extraAmount,
    double? confirmedAmount,
  }) async {
    final response = await _dio.patch(
      '${AppConfig.appPrefix}/owner/bookings/$id/complete',
      data: {
        'extra_amount': ?extraAmount,
        'confirmed_amount': ?confirmedAmount,
      },
    );
    return OwnerBookingModel.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ReviewModel>> getReviews() async {
    final response = await _dio.get('${AppConfig.appPrefix}/owner/reviews');
    return parseDataList(response.data, ReviewModel.fromJson);
  }

  Future<SalonSlotsResponse> fetchOwnerSlots(
    String salonId,
    String date,
  ) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/salons/$salonId/slots',
      queryParameters: {'date': date},
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return SalonSlotsResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<SalonSlotsResponse> setSlotBlocked({
    required String salonId,
    required String slotDate,
    required String slotStart,
    required bool isBlocked,
    String? note,
  }) async {
    final response = await _dio.put(
      '${AppConfig.appPrefix}/owner/salons/$salonId/slots/block',
      data: {
        'slot_date': slotDate,
        'slot_start': slotStart.substring(0, 5),
        'is_blocked': isBlocked,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return SalonSlotsResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> confirmBookingGroupCash({
    required String groupId,
    double? extraAmount,
    double? confirmedAmount,
  }) async {
    await _dio.patch(
      '${AppConfig.appPrefix}/owner/booking-groups/$groupId/confirm-cash',
      data: {
        'extra_amount': ?extraAmount,
        'confirmed_amount': ?confirmedAmount,
      },
    );
  }

  Future<OwnerEarningsSummaryModel> getEarningsSummary() async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/earnings/summary',
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return OwnerEarningsSummaryModel.fromJson(data as Map<String, dynamic>);
  }

  Future<({List<OwnerEarningsTransactionModel> items, int total})>
  getEarningsTransactions({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/earnings/transactions',
      queryParameters: {'page': page, 'limit': limit},
    );
    final body = response.data as Map<String, dynamic>;
    final items = (body['data'] as List<dynamic>)
        .map(
          (e) =>
              OwnerEarningsTransactionModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    final total =
        (body['meta'] as Map<String, dynamic>?)?['total'] as int? ??
        items.length;
    return (items: items, total: total);
  }

  Future<OwnerPayoutAccountModel?> getPayoutAccount() async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/payout-account',
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data == null) return null;
    return OwnerPayoutAccountModel.fromJson(data as Map<String, dynamic>);
  }

  Future<OwnerPayoutAccountModel> upsertPayoutAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    String? upiId,
    String? salonId,
  }) async {
    final response = await _dio.put(
      '${AppConfig.appPrefix}/owner/payout-account',
      data: {
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        if (upiId != null && upiId.isNotEmpty) 'upi_id': upiId,
        if (salonId != null && salonId.isNotEmpty) 'salon_id': salonId,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'];
    return OwnerPayoutAccountModel.fromJson(data as Map<String, dynamic>);
  }
}

final ownerServiceProvider = Provider<OwnerService>((ref) {
  ref.keepAlive();
  return OwnerService(ref.watch(dioProvider));
});

final ownerDashboardSalonScopeProvider =
    NotifierProvider<OwnerDashboardSalonScope, String?>(
      OwnerDashboardSalonScope.new,
    );

class OwnerDashboardSalonScope extends Notifier<String?> {
  @override
  String? build() => null;

  void setScope(String? salonId) => state = salonId;
}

enum OwnerDashboardPeriod {
  last7Days,
  last30Days,
  lifetime;

  String get apiValue => switch (this) {
    OwnerDashboardPeriod.last7Days => '7d',
    OwnerDashboardPeriod.last30Days => '30d',
    OwnerDashboardPeriod.lifetime => 'lifetime',
  };

  String get label => switch (this) {
    OwnerDashboardPeriod.last7Days => 'Last 7 days',
    OwnerDashboardPeriod.last30Days => 'Last 30 days',
    OwnerDashboardPeriod.lifetime => 'Lifetime',
  };
}

final ownerDashboardPeriodProvider =
    NotifierProvider<OwnerDashboardPeriodNotifier, OwnerDashboardPeriod>(
      OwnerDashboardPeriodNotifier.new,
    );

class OwnerDashboardPeriodNotifier extends Notifier<OwnerDashboardPeriod> {
  @override
  OwnerDashboardPeriod build() => OwnerDashboardPeriod.last7Days;

  void select(OwnerDashboardPeriod period) => state = period;
}

final ownerBookingsTodayFilterProvider =
    NotifierProvider<OwnerBookingsTodayFilter, bool>(
      OwnerBookingsTodayFilter.new,
    );

class OwnerBookingsTodayFilter extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() => state = true;

  void clear() => state = false;
}

final ownerDashboardProvider =
    FutureProvider.autoDispose<OwnerDashboardV2Model>((ref) {
      final salonId = ref.watch(ownerDashboardSalonScopeProvider);
      final period = ref.watch(ownerDashboardPeriodProvider);
      return ref
          .watch(ownerServiceProvider)
          .getDashboard(salonId: salonId, period: period);
    });

final ownerSalonsProvider = FutureProvider.autoDispose<List<SalonModel>>((ref) {
  return ref.watch(ownerServiceProvider).getOwnerSalons();
});

final ownerPremiumConfigProvider =
    FutureProvider.autoDispose<PremiumConfigModel>((ref) {
      return ref.watch(ownerServiceProvider).getPremiumBookingConfig();
    });

final ownerSalonApplicationsProvider =
    FutureProvider.autoDispose<List<SalonApplicationModel>>((ref) {
      return ref.watch(ownerServiceProvider).getSalonApplications();
    });

SalonApplicationModel? pendingApplicationForSalon(
  List<SalonApplicationModel> applications,
  String salonId,
) {
  for (final app in applications) {
    // Profile UPDATE no longer goes through approval; ignore leftover UPDATE apps.
    if (app.salonId == salonId && app.isPending && !app.isUpdate) return app;
  }
  return null;
}

final ownerServicesProvider = FutureProvider.family<List<ServiceModel>, String>(
  (ref, salonId) {
    ref.keepAlive();
    return ref.watch(ownerServiceProvider).getSalonServices(salonId);
  },
);

final ownerStaffProvider = FutureProvider.family<List<StaffModel>, String>((
  ref,
  salonId,
) {
  ref.keepAlive();
  return ref.watch(ownerServiceProvider).getSalonStaff(salonId);
});

final ownerAllBookingsProvider =
    FutureProvider.autoDispose<List<OwnerBookingModel>>((ref) {
      return ref.watch(ownerServiceProvider).getBookings();
    });

/// Tracks which owner shell tab is visible. IndexedStack keeps tab screens
/// mounted, so child screens (e.g. bookings) listen here to refresh on open.
class OwnerShellTabIndex extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final ownerShellTabIndexProvider = NotifierProvider<OwnerShellTabIndex, int>(
  OwnerShellTabIndex.new,
);

final ownerBookingsProvider = FutureProvider.autoDispose
    .family<List<OwnerBookingModel>, String?>((ref, status) {
      return ref.watch(ownerServiceProvider).getBookings(status: status);
    });

final ownerReviewsProvider = FutureProvider.autoDispose<List<ReviewModel>>((
  ref,
) {
  return ref.watch(ownerServiceProvider).getReviews();
});

typedef OwnerSlotsKey = ({String salonId, String date});

final ownerSlotsProvider = FutureProvider.autoDispose
    .family<SalonSlotsResponse, OwnerSlotsKey>((ref, key) {
      return ref
          .watch(ownerServiceProvider)
          .fetchOwnerSlots(key.salonId, key.date);
    });

final ownerEarningsSummaryProvider =
    FutureProvider.autoDispose<OwnerEarningsSummaryModel>((ref) {
      return ref.watch(ownerServiceProvider).getEarningsSummary();
    });

final ownerEarningsTransactionsProvider = FutureProvider.autoDispose
    .family<({List<OwnerEarningsTransactionModel> items, int total}), int>((
      ref,
      page,
    ) {
      return ref
          .watch(ownerServiceProvider)
          .getEarningsTransactions(page: page);
    });

final ownerPayoutAccountProvider =
    FutureProvider.autoDispose<OwnerPayoutAccountModel?>((ref) {
      return ref.watch(ownerServiceProvider).getPayoutAccount();
    });

class OwnerSlotActions {
  OwnerSlotActions(this._ref);

  final Ref _ref;

  Future<void> setBlocked({
    required String salonId,
    required String slotDate,
    required String slotStart,
    required bool isBlocked,
    String? note,
  }) async {
    await _ref
        .read(ownerServiceProvider)
        .setSlotBlocked(
          salonId: salonId,
          slotDate: slotDate,
          slotStart: slotStart,
          isBlocked: isBlocked,
          note: note,
        );
    _ref.invalidate(ownerSlotsProvider((salonId: salonId, date: slotDate)));
  }
}

final ownerSlotActionsProvider = Provider<OwnerSlotActions>((ref) {
  ref.keepAlive();
  return OwnerSlotActions(ref);
});

class OwnerBookingActions {
  OwnerBookingActions(this._ref);

  final Ref _ref;

  Future<OwnerBookingModel> accept(String id) async {
    final booking = await _ref.read(ownerServiceProvider).acceptBooking(id);
    _ref.invalidate(ownerBookingsProvider);
    _ref.invalidate(ownerAllBookingsProvider);
    _ref.invalidate(ownerDashboardProvider);
    return booking;
  }

  Future<OwnerBookingModel> reject(String id, {String? reason}) async {
    final booking = await _ref
        .read(ownerServiceProvider)
        .rejectBooking(id, reason: reason);
    _ref.invalidate(ownerBookingsProvider);
    _ref.invalidate(ownerAllBookingsProvider);
    _ref.invalidate(ownerDashboardProvider);
    return booking;
  }

  Future<OwnerBookingModel> complete(
    String id, {
    double? extraAmount,
  }) async {
    final booking = await _ref
        .read(ownerServiceProvider)
        .completeBooking(id, extraAmount: extraAmount);
    _ref.invalidate(ownerBookingsProvider);
    _ref.invalidate(ownerAllBookingsProvider);
    _ref.invalidate(ownerDashboardProvider);
    _ref.invalidate(ownerEarningsSummaryProvider);
    _ref.invalidate(ownerEarningsTransactionsProvider);
    return booking;
  }

  Future<void> confirmCashPayment(
    String groupId, {
    double? extraAmount,
    double? confirmedAmount,
  }) async {
    await _ref
        .read(ownerServiceProvider)
        .confirmBookingGroupCash(
          groupId: groupId,
          extraAmount: extraAmount,
          confirmedAmount: confirmedAmount,
        );
    _ref.invalidate(ownerBookingsProvider);
    _ref.invalidate(ownerAllBookingsProvider);
    _ref.invalidate(ownerDashboardProvider);
    _ref.invalidate(ownerEarningsSummaryProvider);
    _ref.invalidate(ownerEarningsTransactionsProvider);
  }
}

final ownerBookingActionsProvider = Provider<OwnerBookingActions>((ref) {
  ref.keepAlive();
  return OwnerBookingActions(ref);
});

class OwnerOnboardingActions {
  OwnerOnboardingActions(this._ref);

  final Ref _ref;

  Future<void> registerOwner({
    required String businessName,
    String? gstNumber,
  }) async {
    await _ref
        .read(ownerServiceProvider)
        .registerAsOwner(businessName: businessName, gstNumber: gstNumber);
  }

  Future<void> submitApplication(Map<String, dynamic> body) async {
    await _ref.read(ownerServiceProvider).submitSalonApplication(body);
    _ref.invalidate(ownerSalonsProvider);
  }

  Future<List<String>> uploadSalonImages(List<XFile> files) async {
    return _ref.read(ownerServiceProvider).uploadSalonImages(files);
  }

  Future<String> uploadStaffImage(XFile file) async {
    return _ref.read(ownerServiceProvider).uploadStaffImage(file);
  }

  Future<void> submitUpdateRequest({
    required String salonId,
    required Map<String, dynamic> body,
  }) async {
    await _ref
        .read(ownerServiceProvider)
        .updateSalon(salonId: salonId, body: body);
    _ref.invalidate(ownerSalonsProvider);
  }

  Future<void> submitDeactivateRequest({
    required String salonId,
    String? reason,
  }) async {
    await _ref
        .read(ownerServiceProvider)
        .submitSalonDeactivateRequest(salonId: salonId, reason: reason);
    _ref.invalidate(ownerSalonApplicationsProvider);
    _ref.invalidate(ownerSalonsProvider);
  }

  Future<void> submitActivateRequest({
    required String salonId,
    String? reason,
  }) async {
    await _ref
        .read(ownerServiceProvider)
        .submitSalonActivateRequest(salonId: salonId, reason: reason);
    _ref.invalidate(ownerSalonApplicationsProvider);
    _ref.invalidate(ownerSalonsProvider);
  }
}

final ownerOnboardingActionsProvider = Provider<OwnerOnboardingActions>((ref) {
  ref.keepAlive();
  return OwnerOnboardingActions(ref);
});
