import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/location/location_service_provider.dart';
import 'package:saloon_booking/core/location/selected_location.dart';
import 'package:saloon_booking/core/location/user_location_service.dart';
import 'package:saloon_booking/core/utils/salon_geocoding.dart';

const _prefsKey = 'selected_location_v1';
const minimumGpsQueryDistanceMeters = 250.0;
const backgroundGpsRefreshInterval = Duration(minutes: 15);

bool isSignificantGpsChange(
  SelectedLocation current,
  UserLocation next, {
  double minimumDistanceMeters = minimumGpsQueryDistanceMeters,
}) {
  final currentLat = current.latitude;
  final currentLng = current.longitude;
  if (current.source != LocationSource.gps ||
      currentLat == null ||
      currentLng == null) {
    return true;
  }

  const earthRadiusMeters = 6371000.0;
  double radians(double degrees) => degrees * math.pi / 180;
  final latDelta = radians(next.latitude - currentLat);
  final lngDelta = radians(next.longitude - currentLng);
  final a =
      math.sin(latDelta / 2) * math.sin(latDelta / 2) +
      math.cos(radians(currentLat)) *
          math.cos(radians(next.latitude)) *
          math.sin(lngDelta / 2) *
          math.sin(lngDelta / 2);
  final clampedA = a.clamp(0.0, 1.0);
  final distance =
      earthRadiusMeters *
      2 *
      math.atan2(math.sqrt(clampedA), math.sqrt(1 - clampedA));
  return distance >= minimumDistanceMeters;
}

class SelectedLocationState {
  const SelectedLocationState({
    this.location = const SelectedLocation.unset(),
    this.isLoading = false,
    this.gpsDenied = false,
    this.lastGpsFailure,
  });

  final SelectedLocation location;
  final bool isLoading;
  final bool gpsDenied;
  final LocationFetchFailure? lastGpsFailure;

  SelectedLocationState copyWith({
    SelectedLocation? location,
    bool? isLoading,
    bool? gpsDenied,
    LocationFetchFailure? lastGpsFailure,
    bool clearLastGpsFailure = false,
  }) {
    return SelectedLocationState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      gpsDenied: gpsDenied ?? this.gpsDenied,
      lastGpsFailure: clearLastGpsFailure
          ? null
          : (lastGpsFailure ?? this.lastGpsFailure),
    );
  }
}

double _roundCoord(double value) => (value * 1000).roundToDouble() / 1000;

/// Stable key for salon queries; only meaningful when location is settled.
String salonLocationKey(SelectedLocation location) {
  if (!location.isSet) return '';
  if (location.source == LocationSource.manualCity) {
    return 'city:${location.city ?? location.displayLabel}';
  }
  final lat = location.latitude;
  final lng = location.longitude;
  if (lat == null || lng == null) return '';
  return 'gps:${_roundCoord(lat)},${_roundCoord(lng)}';
}

/// Location key used to drive salon list fetches. Empty while GPS is still
/// resolving or when no location is selected.
final settledSalonLocationKeyProvider = Provider<String>((ref) {
  final state = ref.watch(selectedLocationProvider);
  if (state.isLoading || !state.location.isSet) return '';
  return salonLocationKey(state.location);
});

class SelectedLocationNotifier extends Notifier<SelectedLocationState> {
  Future<bool>? _gpsRefreshFuture;
  bool _bootstrapScheduled = false;
  DateTime? _lastBackgroundGpsRefreshAt;

  UserLocationService get _locationService =>
      ref.read(userLocationServiceProvider);

  @override
  SelectedLocationState build() {
    if (!_bootstrapScheduled) {
      _bootstrapScheduled = true;
      Future.microtask(_loadPersisted);
    }
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
        label ?? formatCoordinatesLabel(coords.latitude, coords.longitude);
    final location = SelectedLocation(
      displayLabel: displayLabel,
      source: LocationSource.gps,
      latitude: coords.latitude,
      longitude: coords.longitude,
      city: null,
    );
    state = SelectedLocationState(location: location, gpsDenied: false);
    await _persist(location);

    if (label == null) {
      unawaited(_resolveLabelInBackground(coords));
    }
  }

  Future<void> _resolveLabelInBackground(UserLocation coords) async {
    final resolved = await _locationService.resolveLabel(
      coords.latitude,
      coords.longitude,
    );
    if (resolved == 'Current location') return;

    final current = state.location;
    if (current.latitude != coords.latitude ||
        current.longitude != coords.longitude) {
      return;
    }

    final updated = current.copyWith(displayLabel: resolved);
    state = state.copyWith(location: updated);
    await _persist(updated);
  }

  Future<void> setManualCity(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    final location = SelectedLocation(
      displayLabel: trimmed,
      source: LocationSource.manualCity,
      city: trimmed,
    );
    state = SelectedLocationState(location: location, gpsDenied: false);
    await _persist(location);
  }

  Future<bool> refreshGps({bool silent = false}) {
    final inFlight = _gpsRefreshFuture;
    if (inFlight != null) return inFlight;

    final future = CrashReporting.measureAsync(
      silent ? 'gps_refresh_background' : 'gps_refresh',
      () => _refreshGps(silent: silent),
      slowThreshold: const Duration(seconds: 2),
    );
    _gpsRefreshFuture = future;
    return future.whenComplete(() {
      if (identical(_gpsRefreshFuture, future)) {
        _gpsRefreshFuture = null;
      }
    });
  }

  /// Refreshes GPS in the background after a short delay. Safe to call on
  /// home open when a persisted location is already shown.
  void scheduleBackgroundGpsRefresh() {
    unawaited(_scheduleBackgroundGpsIfNeeded());
  }

  Future<void> _scheduleBackgroundGpsIfNeeded() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final loc = state.location;
    if (!loc.isSet || loc.source != LocationSource.gps) return;
    final lastRefreshAt = _lastBackgroundGpsRefreshAt;
    if (lastRefreshAt != null &&
        DateTime.now().difference(lastRefreshAt) <
            backgroundGpsRefreshInterval) {
      return;
    }
    _lastBackgroundGpsRefreshAt = DateTime.now();
    await refreshGps(silent: true);
  }

  Future<bool> _refreshGps({bool silent = false}) async {
    final hasPersistedLocation = state.location.isSet;
    if (!silent || !hasPersistedLocation) {
      state = state.copyWith(isLoading: true, clearLastGpsFailure: true);
    }
    try {
      final ensure = await _locationService.ensureServiceAndPermission();
      if (!ensure.ready) {
        state = SelectedLocationState(
          location: hasPersistedLocation
              ? state.location
              : const SelectedLocation.unset(),
          isLoading: false,
          gpsDenied: true,
          lastGpsFailure: ensure.failure,
        );
        return false;
      }

      final coords = await _locationService.getCurrentLocation();
      if (coords == null) {
        state = SelectedLocationState(
          location: hasPersistedLocation
              ? state.location
              : const SelectedLocation.unset(),
          isLoading: false,
          gpsDenied: true,
          lastGpsFailure: LocationFetchFailure.timeout,
        );
        return false;
      }
      if (silent &&
          hasPersistedLocation &&
          !isSignificantGpsChange(state.location, coords)) {
        CrashReporting.breadcrumb('gps_refresh_ignored_small_change');
        return true;
      }
      await setFromGps(coords);
      state = state.copyWith(isLoading: false, gpsDenied: false);
      return true;
    } catch (_) {
      state = SelectedLocationState(
        location: hasPersistedLocation
            ? state.location
            : const SelectedLocation.unset(),
        isLoading: false,
        gpsDenied: true,
        lastGpsFailure: LocationFetchFailure.unknown,
      );
      return false;
    }
  }
}

final selectedLocationProvider =
    NotifierProvider<SelectedLocationNotifier, SelectedLocationState>(
      SelectedLocationNotifier.new,
    );
