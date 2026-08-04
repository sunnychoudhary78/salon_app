import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/accent_palette.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_repository.dart';

const accentPaletteStorageKey = 'accent_palette';

class AccentPaletteNotifier extends AsyncNotifier<AccentPalette> {
  @override
  Future<AccentPalette> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return AccentPalette.fromStorage(prefs.getString(accentPaletteStorageKey));
  }

  Future<void> setPalette(AccentPalette palette) async {
    state = AsyncData(palette);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(accentPaletteStorageKey, palette.storageValue);
  }
}

final accentPaletteProvider =
    AsyncNotifierProvider<AccentPaletteNotifier, AccentPalette>(
      AccentPaletteNotifier.new,
    );
