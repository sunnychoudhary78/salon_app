import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/unauthorized_trigger.dart';
import 'package:saloon_booking/core/notifications/notification_service.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/auth/data/repositories/auth_repository.dart';

class PendingSignup {
  const PendingSignup({required this.signupToken, required this.phone});

  final String signupToken;
  final String phone;
}

class PendingSignupNotifier extends Notifier<PendingSignup?> {
  @override
  PendingSignup? build() => null;

  void set(PendingSignup? value) => state = value;

  void clear() => state = null;
}

final pendingSignupProvider =
    NotifierProvider<PendingSignupNotifier, PendingSignup?>(
  PendingSignupNotifier.new,
);

class Auth extends AsyncNotifier<AuthState?> {
  @override
  Future<AuthState?> build() async {
    ref.keepAlive();
    ref.listen(unauthorizedTriggerProvider, (_, __) {
      ref.read(hasApprovedSalonsProvider.notifier).reset();
      ref.read(pendingSignupProvider.notifier).clear();
      state = const AsyncData(null);
    });
    final session = await ref.read(authRepositoryProvider).restoreSession();
    if (session?.salonOwner != null) {
      await ref.read(hasApprovedSalonsProvider.notifier).refresh();
    } else {
      ref.read(hasApprovedSalonsProvider.notifier).reset();
    }
    return session;
  }

  Future<void> requestOtp(String phone) async {
    await ref.read(authRepositoryProvider).requestOtp(phone: phone);
  }

  Future<OtpVerifyResult> verifyOtp(String phone, String otp) async {
    final result = await ref.read(authRepositoryProvider).verifyOtp(
          phone: phone,
          otp: otp,
        );

    if (result.isNewUser) {
      ref.read(pendingSignupProvider.notifier).set(PendingSignup(
        signupToken: result.signupToken!,
        phone: result.phone ?? phone,
      ));
    } else if (result.authState != null) {
      ref.read(pendingSignupProvider.notifier).clear();
      state = AsyncData(result.authState);
      await _syncApprovalState();
    }

    return result;
  }

  Future<void> completeProfile({
    required String name,
    String? email,
  }) async {
    final pending = ref.read(pendingSignupProvider);
    if (pending == null) {
      throw StateError('No pending signup session');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).completeProfile(
            signupToken: pending.signupToken,
            name: name,
            email: email,
          ),
    );
    ref.read(pendingSignupProvider.notifier).clear();
    await _syncApprovalState();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          ),
    );
    await _syncApprovalState();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
            phone: phone,
          ),
    );
    await _syncApprovalState();
  }

  Future<void> refreshProfile() async {
    final current = state.value;
    if (current == null) return;
    final profile = await ref.read(authRepositoryProvider).getProfile();
    state = AsyncData(
      AuthState.fromProfile(current.token, profile),
    );
    await _syncApprovalState();
  }

  Future<void> logout({bool silent = false}) async {
    await ref.read(notificationServiceProvider).unregisterCurrentDevice();
    await ref.read(authRepositoryProvider).logout();
    ref.read(hasApprovedSalonsProvider.notifier).reset();
    ref.read(pendingSignupProvider.notifier).clear();
    if (!silent) {
      state = const AsyncData(null);
    } else {
      state = const AsyncData(null);
    }
  }

  void updateAuthState(AuthState authState) {
    state = AsyncData(authState);
  }

  Future<void> _syncApprovalState() async {
    final current = state.value;
    if (current?.salonOwner != null) {
      await ref.read(hasApprovedSalonsProvider.notifier).refresh();
    } else {
      ref.read(hasApprovedSalonsProvider.notifier).reset();
    }
  }
}

final authProvider = AsyncNotifierProvider<Auth, AuthState?>(Auth.new);
