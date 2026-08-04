import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/theme/accent_palette.dart';
import 'package:saloon_booking/core/theme/accent_palette_provider.dart';
import 'package:saloon_booking/core/theme/app_theme.dart';
import 'package:saloon_booking/features/settings/presentation/widgets/accent_palette_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows palettes and applies a selection immediately', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final palette =
                ref.watch(accentPaletteProvider).value ?? AccentPalette.rose;
            return MaterialApp(
              theme: AppTheme.lightFor(palette),
              home: const Scaffold(
                body: SingleChildScrollView(child: AccentPaletteSwitcher()),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final palette in AccentPalette.values) {
      expect(find.text(palette.label), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('accent-ocean')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(accentPaletteStorageKey),
      AccentPalette.ocean.storageValue,
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
