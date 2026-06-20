import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saloon_booking/core/location/selected_location.dart';
import 'package:saloon_booking/core/location/user_location_service.dart';

const _prefsKey = 'selected_location_v1';

class SelectedLocationState {
  const SelectedLocationState({
    this.location = const SelectedLocation.unset(),
    this.isLoading = false,
    this.gpsDenied = false,
  });

  final SelectedLocation location;
  final bool isLoading;
  final bool gpsDenied;

  SelectedLocationState copyWith({
    SelectedLocation? location,
    bool? isLoading,
    bool? gpsDenied,
  }) {
    return SelectedLocationState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      gpsDenied: gpsDenied ?? this.gpsDenied,
    );
  }
}

class SelectedLocationNotifier extends Notifier<SelectedLocationState> {
  final _locationService = UserLocationService();

  @override
  SelectedLocationState build() {
    _loadPersisted();
    return const SelectedLocationState(isLoading: true);
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final saved = SelectedLocation.fromJson(json);
        if (saved.isSet) {
          state = SelectedLocationState(location: saved);
          return;
        }
      }
    } catch (_) {
      // Ignore corrupt persisted data.
    }
    await refreshGps();
  }

  Future<void> _persist(SelectedLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(location.toJson()));
    } catch (_) {
      // Persistence failure is non-fatal.
    }
  }

  Future<void> setFromGps(UserLocation coords, {String? label}) async {
    final displayLabel =
        label ??
        await _locationService.resolveLabel(coords.latitude, coords.longitude);
    final location = SelectedLocation(
      displayLabel: displayLabel,
      source: LocationSource.gps,
      latitude: coords.latitude,
      longitude: coords.longitude,
      city: null,
    );
    state = SelectedLocationState(location: location, gpsDenied: false);
    await _persist(location);
  }

  Future<void> setManualCity(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    final location = SelectedLocation(
      displayLabel: trimmed,
      source: LocationSource.manualCity,
      city: trimmed,
    );
    state = SelectedLocationState(location: location);
    await _persist(location);
  }

  Future<bool> refreshGps() async {
    state = state.copyWith(isLoading: true);
    try {
      final coords = await _locationService.getCurrentLocation();
      if (coords == null) {
        state = SelectedLocationState(
          location: state.location.isSet
              ? state.location
              : const SelectedLocation(
                  displayLabel: 'Select location',
                  source: LocationSource.gps,
                ),
          isLoading: false,
          gpsDenied: true,
        );
        return false;
      }
      await setFromGps(coords);
      state = state.copyWith(isLoading: false, gpsDenied: false);
      return true;
    } catch (_) {
      state = SelectedLocationState(
        location: state.location.isSet
            ? state.location
            : const SelectedLocation(
                displayLabel: 'Select location',
                source: LocationSource.gps,
              ),
        isLoading: false,
        gpsDenied: true,
      );
      return false;
    }
  }

  Future<void> ensureInitialized() async {
    if (!state.location.isSet && !state.isLoading) {
      await refreshGps();
    }
  }
}

final selectedLocationProvider =
    NotifierProvider<SelectedLocationNotifier, SelectedLocationState>(
  SelectedLocationNotifier.new,
);
