import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/theme/accent_palette.dart';
import 'package:saloon_booking/core/theme/accent_palette_provider.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_repository.dart';

const _audienceModePrefsKey = 'customer_audience_mode_v1';

class AudienceModeNotifier extends AsyncNotifier<AudienceMode> {
  @override
  Future<AudienceMode> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final stored = AudienceMode.tryParse(prefs.getString(_audienceModePrefsKey));
    if (stored != null) return stored;

    final gender = ref.watch(
      authProvider.select((auth) => auth.value?.customer?.gender),
    );
    final mode = AudienceMode.fromGender(gender);
    // First-run gender seed: match accent so Men users aren't stuck on rose.
    Future.microtask(() {
      if (!ref.mounted) return;
      unawaited(_syncAccent(mode));
    });
    return mode;
  }

  Future<void> _syncAccent(AudienceMode mode) {
    return ref
        .read(accentPaletteProvider.notifier)
        .setPalette(AccentPalette.forAudience(mode));
  }

  Future<void> setMode(AudienceMode mode) async {
    state = AsyncData(mode);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_audienceModePrefsKey, mode.apiValue);
    await _syncAccent(mode);
  }

  /// Seeds local preference from profile gender when the user has not chosen yet.
  Future<void> hydrateFromGender(String? gender) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (prefs.containsKey(_audienceModePrefsKey)) return;
    final mode = AudienceMode.fromGender(gender);
    state = AsyncData(mode);
    await prefs.setString(_audienceModePrefsKey, mode.apiValue);
    await _syncAccent(mode);
  }
}

final audienceModeProvider =
    AsyncNotifierProvider<AudienceModeNotifier, AudienceMode>(
      AudienceModeNotifier.new,
    );

/// Synchronous convenience for UI that already has a fallback.
final audienceModeValueProvider = Provider<AudienceMode>((ref) {
  return ref.watch(audienceModeProvider).value ?? AudienceMode.men;
});
