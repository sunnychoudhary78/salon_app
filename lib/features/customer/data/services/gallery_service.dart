import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/customer/data/models/gallery_post_model.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

class GalleryService {
  GalleryService(this._dio);

  final Dio _dio;

  Future<List<GalleryPostModel>> getSalonGallery(
    String salonId, {
    String? staffId,
    String? serviceId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (staffId != null && staffId.isNotEmpty) queryParams['staff_id'] = staffId;
    if (serviceId != null && serviceId.isNotEmpty) queryParams['service_id'] = serviceId;

    final response = await _dio.get(
      '${AppConfig.appPrefix}/salons/$salonId/gallery',
      queryParameters: queryParams,
    );

    final rawList = response.data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((json) => GalleryPostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<({StaffModel staff, List<GalleryPostModel> portfolio})> getStaffPortfolio(
    String staffId,
  ) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/staff/$staffId/portfolio',
    );

    final staffJson = response.data['staff'] as Map<String, dynamic>;
    final portfolioList = response.data['portfolio'] as List<dynamic>? ?? [];

    return (
      staff: StaffModel.fromJson(staffJson),
      portfolio: portfolioList
          .map((json) => GalleryPostModel.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<({bool liked, int likesCount})> toggleLike(String postId) async {
    final response = await _dio.post(
      '${AppConfig.appPrefix}/gallery/$postId/like',
    );

    return (
      liked: response.data['liked'] as bool? ?? false,
      likesCount: (response.data['likes_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<GalleryPostModel>> getMyTransformations() async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/customer/my-transformations',
    );

    final rawList = response.data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((json) => GalleryPostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<GalleryPostModel> updateConsent(String postId, String consent) async {
    final response = await _dio.put(
      '${AppConfig.appPrefix}/customer/my-transformations/$postId/consent',
      data: {'consent': consent},
    );

    return GalleryPostModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // Owner upload
  Future<GalleryPostModel> ownerCreatePost({
    required String salonId,
    required File beforeImage,
    required File afterImage,
    required String customerPhone,
    String? title,
    String? description,
    String? staffId,
    String? serviceId,
    bool isPublic = true,
  }) async {
    final formData = FormData.fromMap({
      'before_image': await MultipartFile.fromFile(
        beforeImage.path,
        filename: beforeImage.path.split('/').last,
      ),
      'after_image': await MultipartFile.fromFile(
        afterImage.path,
        filename: afterImage.path.split('/').last,
      ),
      if (title != null && title.isNotEmpty) 'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      if (staffId != null && staffId.isNotEmpty) 'staff_id': staffId,
      if (serviceId != null && serviceId.isNotEmpty) 'service_id': serviceId,
      'customer_phone': customerPhone,
      'is_public': isPublic.toString(),
    });

    final response = await _dio.post(
      '${AppConfig.appPrefix}/owner/salons/$salonId/gallery',
      data: formData,
    );

    return GalleryPostModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<GalleryPostModel>> ownerListPosts(String salonId) async {
    final response = await _dio.get(
      '${AppConfig.appPrefix}/owner/salons/$salonId/gallery',
    );

    final rawList = response.data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((json) => GalleryPostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> ownerDeletePost(String postId) async {
    await _dio.delete(
      '${AppConfig.appPrefix}/owner/gallery/$postId',
    );
  }
}

final galleryServiceProvider = Provider<GalleryService>((ref) {
  ref.keepAlive();
  return GalleryService(ref.watch(dioProvider));
});

// Providers
final salonGalleryProvider = FutureProvider.autoDispose
    .family<List<GalleryPostModel>, String>((ref, salonId) {
  return ref.watch(galleryServiceProvider).getSalonGallery(salonId);
});

final ownerGalleryProvider = FutureProvider.autoDispose
    .family<List<GalleryPostModel>, String>((ref, salonId) {
  return ref.watch(galleryServiceProvider).ownerListPosts(salonId);
});

final staffPortfolioProvider = FutureProvider.autoDispose
    .family<({StaffModel staff, List<GalleryPostModel> portfolio}), String>((ref, staffId) {
  return ref.watch(galleryServiceProvider).getStaffPortfolio(staffId);
});

final myTransformationsProvider = FutureProvider.autoDispose<List<GalleryPostModel>>((ref) {
  return ref.watch(galleryServiceProvider).getMyTransformations();
});
