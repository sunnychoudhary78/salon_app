import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
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

    final urls = (response.data as Map<String, dynamic>)['data']['urls']
        as List<dynamic>;
    return urls.map((e) => e as String).toList();
  }

  Future<List<SalonApplicationModel>> getSalonApplications({String? status}) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/salon-applications',
      queryParameters: {if (status != null) 'status': status},
    );
    return parseDataList(response.data, SalonApplicationModel.fromJson);
  }

  Future<SalonApplicationModel> submitSalonUpdateRequest({
    required String salonId,
    required Map<String, dynamic> body,
  }) async {
    return submitSalonApplication({
      'application_type': 'UPDATE',
      'salon_id': salonId,
      ...body,
    });
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

  Future<List<ServiceModel>> getSalonServices(String salonId) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/salons/$salonId/services',
    );
    return parseDataList(response.data, ServiceModel.fromJson);
  }

  Future<List<ServiceCategoryModel>> getServiceCategories() async {
    final response =
        await _dio.get('${AppConfig.appPrefix}/service-categories');
    return parseDataList(response.data, ServiceCategoryModel.fromJson);
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

  Future<OwnerDashboardModel> getDashboard() async {
    final response = await _dio.get('${AppConfig.appPrefix}/owner/dashboard');
    return OwnerDashboardModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<OwnerBookingModel>> getBookings({String? status}) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/bookings',
      queryParameters: {if (status != null) 'status': status},
    );
    return (response.data['data'] as List<dynamic>)
        .map((e) => OwnerBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OwnerBookingModel> acceptBooking(String id) async {
    final response =
        await _dio.patch('${AppConfig.appPrefix}/owner/bookings/$id/accept');
    return OwnerBookingModel.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<OwnerBookingModel> rejectBooking(
    String id, {
    String? reason,
  }) async {
    final response = await _dio.patch(
      '${AppConfig.appPrefix}/owner/bookings/$id/reject',
      data: {if (reason != null) 'rejection_reason': reason},
    );
    return OwnerBookingModel.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<OwnerBookingModel> completeBooking(String id) async {
    final response =
        await _dio.patch('${AppConfig.appPrefix}/owner/bookings/$id/complete');
    return OwnerBookingModel.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<List<ReviewModel>> getReviews() async {
    final response = await _dio.get('${AppConfig.appPrefix}/owner/reviews');
    return parseDataList(response.data, ReviewModel.fromJson);
  }

  Future<SalonSlotsResponse> fetchOwnerSlots(String salonId, String date) async {
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
}

final ownerServiceProvider = Provider<OwnerService>((ref) {
  ref.keepAlive();
  return OwnerService(ref.watch(dioProvider));
});

final ownerDashboardProvider =
    FutureProvider.autoDispose<OwnerDashboardModel>((ref) {
  return ref.watch(ownerServiceProvider).getDashboard();
});

final ownerSalonsProvider = FutureProvider.autoDispose<List<SalonModel>>((ref) {
  return ref.watch(ownerServiceProvider).getOwnerSalons();
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
    if (app.salonId == salonId && app.isPending) return app;
  }
  return null;
}

final ownerServicesProvider =
    FutureProvider.family<List<ServiceModel>, String>(
  (ref, salonId) {
    ref.keepAlive();
    return ref.watch(ownerServiceProvider).getSalonServices(salonId);
  },
);

final serviceCategoriesProvider =
    FutureProvider<List<ServiceCategoryModel>>((ref) {
  ref.keepAlive();
  return ref.watch(ownerServiceProvider).getServiceCategories();
});

final ownerAllBookingsProvider =
    FutureProvider.autoDispose<List<OwnerBookingModel>>((ref) {
  return ref.watch(ownerServiceProvider).getBookings();
});

final ownerBookingsProvider =
    FutureProvider.autoDispose.family<List<OwnerBookingModel>, String?>(
  (ref, status) {
    return ref.watch(ownerServiceProvider).getBookings(status: status);
  },
);

final ownerReviewsProvider =
    FutureProvider.autoDispose<List<ReviewModel>>((ref) {
  return ref.watch(ownerServiceProvider).getReviews();
});

typedef OwnerSlotsKey = ({String salonId, String date});

final ownerSlotsProvider =
    FutureProvider.autoDispose.family<SalonSlotsResponse, OwnerSlotsKey>(
  (ref, key) {
    return ref
        .watch(ownerServiceProvider)
        .fetchOwnerSlots(key.salonId, key.date);
  },
);

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
    await _ref.read(ownerServiceProvider).setSlotBlocked(
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

  Future<void> accept(String id) async {
    await _ref.read(ownerServiceProvider).acceptBooking(id);
    _ref.invalidate(ownerBookingsProvider);
    _ref.invalidate(ownerAllBookingsProvider);
    _ref.invalidate(ownerDashboardProvider);
  }

  Future<void> reject(String id, {String? reason}) async {
    await _ref.read(ownerServiceProvider).rejectBooking(id, reason: reason);
    _ref.invalidate(ownerBookingsProvider);
    _ref.invalidate(ownerAllBookingsProvider);
    _ref.invalidate(ownerDashboardProvider);
  }

  Future<void> complete(String id) async {
    await _ref.read(ownerServiceProvider).completeBooking(id);
    _ref.invalidate(ownerBookingsProvider);
    _ref.invalidate(ownerAllBookingsProvider);
    _ref.invalidate(ownerDashboardProvider);
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
    await _ref.read(ownerServiceProvider).registerAsOwner(
          businessName: businessName,
          gstNumber: gstNumber,
        );
  }

  Future<void> submitApplication(Map<String, dynamic> body) async {
    await _ref.read(ownerServiceProvider).submitSalonApplication(body);
    _ref.invalidate(ownerSalonsProvider);
  }

  Future<List<String>> uploadSalonImages(List<XFile> files) async {
    return _ref.read(ownerServiceProvider).uploadSalonImages(files);
  }

  Future<void> submitUpdateRequest({
    required String salonId,
    required Map<String, dynamic> body,
  }) async {
    await _ref.read(ownerServiceProvider).submitSalonUpdateRequest(
          salonId: salonId,
          body: body,
        );
    _ref.invalidate(ownerSalonApplicationsProvider);
    _ref.invalidate(ownerSalonsProvider);
  }

  Future<void> submitDeactivateRequest({
    required String salonId,
    String? reason,
  }) async {
    await _ref.read(ownerServiceProvider).submitSalonDeactivateRequest(
          salonId: salonId,
          reason: reason,
        );
    _ref.invalidate(ownerSalonApplicationsProvider);
    _ref.invalidate(ownerSalonsProvider);
  }

  Future<void> submitActivateRequest({
    required String salonId,
    String? reason,
  }) async {
    await _ref.read(ownerServiceProvider).submitSalonActivateRequest(
          salonId: salonId,
          reason: reason,
        );
    _ref.invalidate(ownerSalonApplicationsProvider);
    _ref.invalidate(ownerSalonsProvider);
  }
}

final ownerOnboardingActionsProvider = Provider<OwnerOnboardingActions>((ref) {
  ref.keepAlive();
  return OwnerOnboardingActions(ref);
});
