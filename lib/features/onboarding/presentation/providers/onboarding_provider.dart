import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_repository.dart';

class OnboardingCompleted extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    ref.keepAlive();
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return OnboardingRepository(prefs).isCompleted();
  }

  Future<void> complete() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await OnboardingRepository(prefs).setCompleted();
    state = const AsyncData(true);
  }
}

final onboardingCompletedProvider =
    AsyncNotifierProvider<OnboardingCompleted, bool>(OnboardingCompleted.new);
