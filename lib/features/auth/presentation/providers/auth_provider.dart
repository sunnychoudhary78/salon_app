import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/network/unauthorized_trigger.dart';
import 'package:saloon_booking/core/notifications/notification_service.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/providers/user_data_invalidation.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/auth/data/repositories/auth_repository.dart';
import 'package:saloon_booking/main.dart';

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
      // Run after this build completes so authProvider.value is available.
      Future.microtask(
        () => ref
            .read(hasApprovedSalonsProvider.notifier)
            .refresh(authOverride: session),
      );
    } else {
      ref.read(hasApprovedSalonsProvider.notifier).reset();
    }

    return session;
  }

  Future<void> requestOtp(String phone) async {
    await ref.read(authRepositoryProvider).requestOtp(phone: phone);
  }

  Future<OtpVerifyResult> verifyOtp(String phone, String otp) async {
    final result = await ref
        .read(authRepositoryProvider)
        .verifyOtp(phone: phone, otp: otp);

    if (result.isNewUser) {
      ref
          .read(pendingSignupProvider.notifier)
          .set(
            PendingSignup(
              signupToken: result.signupToken!,
              phone: result.phone ?? phone,
            ),
          );
    } else if (result.authState != null) {
      ref.read(pendingSignupProvider.notifier).clear();
      state = AsyncData(result.authState);
      await _syncApprovalState(result.authState);
    }

    return result;
  }

  Future<void> completeProfile({
    required String name,
    required String gender,
    String? email,
  }) async {
    final pending = ref.read(pendingSignupProvider);
    if (pending == null) {
      throw StateError('No pending signup session');
    }

    final authState = await ref
        .read(authRepositoryProvider)
        .completeProfile(
          signupToken: pending.signupToken,
          name: name,
          gender: gender,
          email: email,
        );
    ref.read(pendingSignupProvider.notifier).clear();
    state = AsyncData(authState);
    await _syncApprovalState(authState);
  }

  Future<void> refreshProfile() async {
    final current = state.value;
    if (current == null) return;
    try {
      CrashReporting.breadcrumb('refresh_profile');
      final profile = await ref.read(authRepositoryProvider).getProfile();
      state = AsyncData(AuthState.fromProfile(current.token, profile));
      await _syncApprovalState(state.value);
    } catch (e, stack) {
      CrashReporting.recordError(e, stack, reason: 'refreshProfile');
      rethrow;
    }
  }

  Future<void> logout({bool silent = false}) async {
    invalidateAllUserScopedData(ref);
    await ref.read(notificationServiceProvider).unregisterCurrentDevice();
    await ref.read(authRepositoryProvider).logout();
    ref.read(hasApprovedSalonsProvider.notifier).reset();
    ref.read(pendingSignupProvider.notifier).clear();
    state = const AsyncData(null);
    Root.restartApp();
  }

  void updateAuthState(AuthState authState) {
    state = AsyncData(authState);
  }

  Future<void> _syncApprovalState([AuthState? session]) async {
    final current = session ?? state.value;
    if (current?.salonOwner != null) {
      await ref
          .read(hasApprovedSalonsProvider.notifier)
          .refresh(authOverride: current);
    } else {
      ref.read(hasApprovedSalonsProvider.notifier).reset();
    }
  }
}

final authProvider = AsyncNotifierProvider<Auth, AuthState?>(Auth.new);
