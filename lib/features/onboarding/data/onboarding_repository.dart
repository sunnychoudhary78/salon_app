import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  CrashReporting.breadcrumb('shared_prefs_get_instance');
  return withStorageTimeout(
    SharedPreferences.getInstance(),
    label: 'SharedPreferences.getInstance',
  );
});

class OnboardingRepository {
  OnboardingRepository(this._prefs);

  final SharedPreferences _prefs;

  Future<bool> isCompleted() async {
    return _prefs.getBool(OnboardingConstants.onboardingCompletedKey) ?? false;
  }

  Future<void> setCompleted() async {
    await _prefs.setBool(OnboardingConstants.onboardingCompletedKey, true);
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return OnboardingRepository(prefs);
});
