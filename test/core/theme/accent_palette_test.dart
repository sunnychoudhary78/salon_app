import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/theme/accent_palette.dart';
import 'package:saloon_booking/core/theme/accent_palette_provider.dart';
import 'package:saloon_booking/core/theme/app_theme.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccentPaletteNotifier', () {
    test('defaults to rose and persists a selection', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(accentPaletteProvider.future),
        AccentPalette.rose,
      );

      await container
          .read(accentPaletteProvider.notifier)
          .setPalette(AccentPalette.emerald);

      expect(
        container.read(accentPaletteProvider).value,
        AccentPalette.emerald,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(accentPaletteStorageKey),
        AccentPalette.emerald.storageValue,
      );
    });

    test('restores a stored palette and rejects unknown values', () async {
      SharedPreferences.setMockInitialValues({
        accentPaletteStorageKey: AccentPalette.ocean.storageValue,
      });
      var container = ProviderContainer();
      expect(
        await container.read(accentPaletteProvider.future),
        AccentPalette.ocean,
      );
      container.dispose();

      SharedPreferences.setMockInitialValues({
        accentPaletteStorageKey: 'not-a-palette',
      });
      container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        await container.read(accentPaletteProvider.future),
        AccentPalette.rose,
      );
    });

    test('migrates the previous champagne selection to gold', () async {
      SharedPreferences.setMockInitialValues({
        accentPaletteStorageKey: 'champagne',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(accentPaletteProvider.future),
        AccentPalette.gold,
      );
    });
  });

  test('each palette drives light and dark theme accent tokens', () {
    for (final palette in AccentPalette.values) {
      final light = AppTheme.lightFor(palette);
      final dark = AppTheme.darkFor(palette);
      final lightColors = light.extension<AppThemeExtension>()!;
      final darkColors = dark.extension<AppThemeExtension>()!;

      expect(lightColors.accent, palette.tokens.accent);
      expect(darkColors.accent, palette.tokens.accentLight);
      expect(lightColors.onAccent, palette.tokens.onAccent);
      expect(darkColors.onAccent, palette.tokens.onAccent);
      expect(light.colorScheme.secondary, palette.tokens.accent);
      expect(dark.colorScheme.secondary, palette.tokens.accentLight);
      expect(light.colorScheme.onSecondary, palette.tokens.onAccent);
      expect(dark.colorScheme.onSecondary, palette.tokens.onAccent);
    }
  });
}
