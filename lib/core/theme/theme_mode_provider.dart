import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_repository.dart';

const _themeModeKey = 'theme_mode';

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final stored = prefs.getString(_themeModeKey);
    return _fromStorage(stored);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_themeModeKey, _toStorage(mode));
  }

  Future<void> setLight() => setMode(ThemeMode.light);

  Future<void> setDark() => setMode(ThemeMode.dark);

  Future<void> setSystem() => setMode(ThemeMode.system);

  static ThemeMode _fromStorage(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  static String _toStorage(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
