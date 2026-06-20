import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/auth/data/repositories/auth_repository.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';

class ProfileService {
  ProfileService(this._dio);

  final Dio _dio;

  Future<ProfileResponse> updateProfile(Map<String, dynamic> body) async {
    final response =
        await _dio.patch('${AppConfig.appPrefix}/profile', data: body);
    return ProfileResponse.fromJson(response.data as Map<String, dynamic>);
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
    String? gender,
    String? dob,
  }) async {
    final response = await _ref.read(profileServiceProvider).updateProfile({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email.isEmpty ? null : email,
      if (profileImage != null) 'profile_image': profileImage,
      if (gender != null) 'gender': gender,
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

  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    await _ref.read(authRepositoryProvider).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
  }
}

final profileActionsProvider = Provider<ProfileActions>((ref) {
  ref.keepAlive();
  return ProfileActions(ref);
});
