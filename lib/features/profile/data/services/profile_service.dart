import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';

class ProfileService {
  ProfileService(this._dio);

  final Dio _dio;

  Future<ProfileResponse> updateProfile(Map<String, dynamic> body) async {
    final response =
        await _dio.patch('${AppConfig.appPrefix}/profile', data: body);
    return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> uploadProfileImage(XFile file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    final response = await _dio.post(
      '${AppConfig.appPrefix}/uploads/profile-image',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    return (response.data as Map<String, dynamic>)['data']['url'] as String;
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  ref.keepAlive();
  return ProfileService(ref.watch(dioProvider));
});

class ProfileActions {
  ProfileActions(this._ref);

  final Ref _ref;

  Future<void> updateProfileFields({
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    bool clearProfileImage = false,
    String? dob,
  }) async {
    final response = await _ref.read(profileServiceProvider).updateProfile({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email.isEmpty ? null : email,
      if (clearProfileImage) 'profile_image': null,
      if (!clearProfileImage && profileImage != null)
        'profile_image': profileImage,
      if (dob != null) 'dob': dob,
    });
    final current = _ref.read(authProvider).value;
    if (current != null) {
      _ref.read(authProvider.notifier).updateAuthState(
            AuthState.fromProfile(current.token, response),
          );
      await _ref.read(hasApprovedSalonsProvider.notifier).refresh();
    }
  }

  Future<String> uploadProfileImage(XFile file) {
    return _ref.read(profileServiceProvider).uploadProfileImage(file);
  }
}

final profileActionsProvider = Provider<ProfileActions>((ref) {
  ref.keepAlive();
  return ProfileActions(ref);
});
