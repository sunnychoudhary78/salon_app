import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saloon_booking/core/location/location_service_provider.dart';
import 'package:saloon_booking/core/location/user_location_service.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/salon_geocoding.dart';
import 'package:saloon_booking/core/utils/salon_reverse_geocoding.dart';
import 'package:saloon_booking/features/owner/data/models/place_suggestion.dart';
import 'package:saloon_booking/features/owner/data/models/salon_location_selection.dart';
import 'package:saloon_booking/features/owner/data/services/places_search_service.dart';
import 'package:saloon_booking/shared/widgets/location_error_hint.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';


enum MapDisplayState { loading, interactive, unavailable }

const _defaultMapCenter = LatLng(20.5937, 78.9629);
const _mapInitTimeout = Duration(seconds: 8);
const _mapInitTimeoutWhileGps = Duration(seconds: 15);
const _searchDebounceMs = 400;
const _idleReverseDebounceMs = 350;
const _biasRadiusMeters = 50000;

Future<SalonLocationSelection?> showOwnerSalonLocationMapSheet(
  BuildContext context, {
  SalonLocationSelection? initial,
}) {
  return showModalBottomSheet<SalonLocationSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.94,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: _OwnerSalonLocationMapSheet(initial: initial),
      ),
    ),
  );
}

class _OwnerSalonLocationMapSheet extends ConsumerStatefulWidget {
  const _OwnerSalonLocationMapSheet({this.initial});

  final SalonLocationSelection? initial;

  @override
  ConsumerState<_OwnerSalonLocationMapSheet> createState() =>
      _OwnerSalonLocationMapSheetState();
}

class _OwnerSalonLocationMapSheetState
    extends ConsumerState<_OwnerSalonLocationMapSheet>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _random = Random();

  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  Timer? _mapInitTimer;
  Timer? _idleReverseDebounce;
  CancelToken? _searchCancelToken;
  CancelToken? _reverseCancelToken;

  MapDisplayState _mapState = MapDisplayState.loading;
  SalonLocationSelection? _draft;
  LatLng _cameraTarget = _defaultMapCenter;
  /// Camera we intend to show; applied when the map controller is ready.
  LatLng? _pendingCameraTarget;
  List<PlaceSuggestion> _suggestions = [];
  bool _searchLoading = false;
  bool _gpsLoading = false;
  bool _reverseGeocoding = false;
  String? _searchError;
  String? _actionError;
  LocationFetchFailure? _lastGpsFailure;
  bool _suppressSearch = false;
  String? _selectingPlaceId;
  String _sessionToken = '';
  int _reverseRequestId = 0;
  bool _skipNextIdleReverse = false;
  bool _mapReady = false;
  /// Ensures primary auto GPS runs at most once per sheet instance.
  bool _didAttemptAutoGpsInit = false;
  /// True once auto/manual GPS successfully moved the camera.
  bool _autoGpsSucceeded = false;
  /// One silent retry after user returns from Settings / system location UI.
  bool _didRetryGpsOnResume = false;
  /// Whether this sheet instance should auto-bias from GPS (new salon).
  bool _allowAutoGps = false;
  bool _gpsFetchInFlight = false;
  /// True while resolving GPS + address on open (shows loading overlay).
  bool _initializingLocation = false;

  static const _gpsRetryDelays = <Duration>[
    Duration(milliseconds: 300),
    Duration(milliseconds: 700),
    Duration(milliseconds: 1200),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionToken = _newSessionToken();
    _startMapInitTimeout();

    final initial = widget.initial;
    // Edit / reopen with saved coordinates: never auto-GPS (preserve pin).
    if (initial != null &&
        isValidSalonCoordinates(initial.latitude, initial.longitude)) {
      final target = LatLng(initial.latitude, initial.longitude);
      _cameraTarget = target;
      _pendingCameraTarget = target;
      _draft = initial;
      if (initial.displayLabel.isNotEmpty) {
        _searchController.text = initial.displayLabel;
      }
      // No-op early return inside bootstrap when coords already valid.
      unawaited(_bootstrapFromInitial());
      return;
    }

    _allowAutoGps = true;
    // Show loading on first frame while GPS + address resolve.
    _initializingLocation = true;
    // New salon (or initial without coords): address bootstrap, then GPS +
    // reverse-geocode into search bar. Failure keeps India-center fallback.
    unawaited(_initializeLocationForNewSalon());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _mapInitTimer?.cancel();
    _idleReverseDebounce?.cancel();
    _searchCancelToken?.cancel();
    _reverseCancelToken?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_allowAutoGps || _autoGpsSucceeded || _didRetryGpsOnResume) return;
    if (_gpsFetchInFlight || _hasUsableCameraCoordinates()) return;
    _didRetryGpsOnResume = true;
    // User may have enabled location in Settings; retry once with address fill.
    unawaited(_retryAutoGpsWithLoading());
  }

  void _startMapInitTimeout() {
    _mapInitTimer?.cancel();
    final duration =
        _initializingLocation ? _mapInitTimeoutWhileGps : _mapInitTimeout;
    _mapInitTimer = Timer(duration, () {
      if (!mounted) return;
      // Keep waiting while GPS permission / fix is in progress.
      if (_initializingLocation && _mapState == MapDisplayState.loading) {
        _startMapInitTimeout();
        return;
      }
      if (_mapState == MapDisplayState.loading) {
        setState(() => _mapState = MapDisplayState.unavailable);
      }
    });
  }

  bool _isDefaultCameraTarget() {
    return (_cameraTarget.latitude - _defaultMapCenter.latitude).abs() < 0.001 &&
        (_cameraTarget.longitude - _defaultMapCenter.longitude).abs() < 0.001;
  }

  /// Bias only after GPS / edit coords / user pan — never India centroid.
  PlacesSearchBias? _placesBiasOrNull() {
    if (_isDefaultCameraTarget()) return null;
    return PlacesSearchBias(
      latitude: _cameraTarget.latitude,
      longitude: _cameraTarget.longitude,
      radiusMeters: _biasRadiusMeters,
    );
  }

  String _newSessionToken() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final salt = _random.nextInt(1 << 32);
    return '$now-$salt';
  }

  void _rotateSessionToken() {
    _sessionToken = _newSessionToken();
  }

  Future<void> _bootstrapFromInitial() async {
    final initial = widget.initial;
    if (initial == null) return;

    if (isValidSalonCoordinates(initial.latitude, initial.longitude)) {
      return;
    }

    if (initial.street.isNotEmpty &&
        initial.city.isNotEmpty &&
        initial.state.isNotEmpty) {
      final geocoded = await geocodeSalonAddress(
        address: initial.street,
        city: initial.city,
        state: initial.state,
      );
      if (!mounted || geocoded == null) return;
      final selection = initial.copyWith(
        latitude: geocoded.latitude,
        longitude: geocoded.longitude,
        formattedAddress: initial.formattedAddress.isNotEmpty
            ? initial.formattedAddress
            : geocoded.label,
      );
      _applyDraft(selection, moveCamera: _mapReady, skipIdleReverse: true);
      _suppressSearch = true;
      _searchController.text = selection.displayLabel;
    }
  }

  /// True when we already have a pin from edit/reopen or address geocode.
  bool _hasUsableCameraCoordinates() {
    final draft = _draft;
    if (draft != null &&
        isValidSalonCoordinates(draft.latitude, draft.longitude)) {
      return true;
    }
    final initial = widget.initial;
    return initial != null &&
        isValidSalonCoordinates(initial.latitude, initial.longitude);
  }

  /// Auto GPS only for new salons without coordinates so edit flow and
  /// address-bootstrap are never overridden by device location.
  Future<void> _initializeLocationForNewSalon() async {
    _startMapInitTimeout();

    try {
      await _bootstrapFromInitial();
      if (!mounted) return;

      // Bootstrap may have set coords from address geocode — skip GPS.
      if (_hasUsableCameraCoordinates()) return;

      if (_didAttemptAutoGpsInit) return;
      _didAttemptAutoGpsInit = true;

      // Move map + reverse-geocode into search bar / draft.
      // Failure keeps India-center; user can still search or tap FAB.
      await _goToDeviceLocation(showErrors: false, reverseGeocode: true);
    } finally {
      if (mounted) {
        setState(() => _initializingLocation = false);
        _startMapInitTimeout();
      }
    }
  }

  Future<void> _retryAutoGpsWithLoading() async {
    if (!mounted) return;
    setState(() => _initializingLocation = true);
    _startMapInitTimeout();
    try {
      await _goToDeviceLocation(showErrors: false, reverseGeocode: true);
    } finally {
      if (mounted) {
        setState(() => _initializingLocation = false);
        _startMapInitTimeout();
      }
    }
  }

  /// Shared GPS path for auto-init (silent) and Current Location FAB (verbose).
  /// Retries after permission/service enable — GPS often needs a cold start.
  Future<UserLocation?> _fetchDeviceCoordinates({
    required bool showErrors,
  }) async {
    try {
      final service = ref.read(userLocationServiceProvider);
      final ensure = await service.ensureServiceAndPermission();
      if (!mounted) return null;

      // Always attempt a fix with backoff — user may enable GPS during/after
      // the permission prompt even when ensure reported not ready.
      UserLocation? coords = await service.getCurrentLocation(
        timeout: const Duration(seconds: 12),
      );
      if (!mounted) return null;

      for (final delay in _gpsRetryDelays) {
        if (coords != null) break;
        await Future<void>.delayed(delay);
        if (!mounted) return null;
        coords = await service.getCurrentLocation(
          timeout: const Duration(seconds: 15),
        );
        if (!mounted) return null;
      }

      if (coords == null) {
        if (showErrors) {
          final failure = ensure.ready
              ? LocationFetchFailure.timeout
              : (ensure.failure ?? LocationFetchFailure.timeout);
          setState(() {
            _gpsLoading = false;
            _actionError = locationFailureMessage(failure);
            _lastGpsFailure = failure;
          });
        }
        return null;
      }
      return coords;
    } catch (_) {
      if (!mounted) return null;
      if (showErrors) {
        setState(() {
          _gpsLoading = false;
          _reverseGeocoding = false;
          _actionError = locationFailureMessage(LocationFetchFailure.unknown);
          _lastGpsFailure = LocationFetchFailure.unknown;
        });
      }
      return null;
    }
  }

  /// Shared by auto-init (bias only) and Current Location FAB (bias + address).
  Future<void> _goToDeviceLocation({
    required bool showErrors,
    required bool reverseGeocode,
  }) async {
    if (_gpsFetchInFlight) return;
    _gpsFetchInFlight = true;

    try {
      if (showErrors) {
        setState(() {
          _gpsLoading = true;
          _actionError = null;
          _lastGpsFailure = null;
        });
      }

      final coords = await _fetchDeviceCoordinates(showErrors: showErrors);
      if (!mounted) return;
      if (coords == null) {
        if (showErrors && _gpsLoading) {
          setState(() => _gpsLoading = false);
        }
        return;
      }

      final target = LatLng(coords.latitude, coords.longitude);
      _autoGpsSucceeded = true;

      if (showErrors) {
        setState(() => _gpsLoading = false);
      }

      // setState + pending + animate when ready (avoids stuck India-center map).
      await _applyCameraTarget(target, skipIdleReverse: true);

      if (reverseGeocode) {
        await _reverseGeocodeAt(target, showErrors: showErrors);
      }
    } finally {
      _gpsFetchInFlight = false;
    }
  }

  /// Updates autocomplete bias and moves the map when the controller exists.
  Future<void> _applyCameraTarget(
    LatLng target, {
    required bool skipIdleReverse,
  }) async {
    if (!mounted) return;
    setState(() {
      _cameraTarget = target;
      _pendingCameraTarget = target;
    });
    if (_mapReady && _mapController != null) {
      await _animateTo(
        target.latitude,
        target.longitude,
        skipIdleReverse: skipIdleReverse,
      );
      if (mounted) {
        setState(() => _pendingCameraTarget = null);
      }
    }
  }

  void _applyDraft(
    SalonLocationSelection selection, {
    bool moveCamera = true,
    bool skipIdleReverse = false,
  }) {
    final target = LatLng(selection.latitude, selection.longitude);
    setState(() {
      _draft = selection;
      _cameraTarget = target;
      _pendingCameraTarget = moveCamera ? target : _pendingCameraTarget;
      _actionError = null;
    });
    if (moveCamera) {
      unawaited(
        _applyCameraTarget(target, skipIdleReverse: skipIdleReverse),
      );
    }
  }

  Future<void> _animateTo(
    double latitude,
    double longitude, {
    bool skipIdleReverse = true,
  }) async {
    final controller = _mapController;
    if (controller == null) return;
    _skipNextIdleReverse = skipIdleReverse;
    _cameraTarget = LatLng(latitude, longitude);
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 16),
      );
    } catch (_) {
      // Controller may be disposed mid-flight; pending target retries on recreate.
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapInitTimer?.cancel();
    _mapController = controller;
    if (!mounted) return;
    setState(() {
      _mapState = MapDisplayState.interactive;
      _mapReady = true;
    });

    // Prefer explicit pending target (GPS / draft), then draft coords.
    final pending = _pendingCameraTarget;
    if (pending != null) {
      unawaited(
        _animateTo(
          pending.latitude,
          pending.longitude,
          skipIdleReverse: true,
        ).then((_) {
          if (mounted) setState(() => _pendingCameraTarget = null);
        }),
      );
      return;
    }

    final draft = _draft;
    if (draft != null &&
        isValidSalonCoordinates(draft.latitude, draft.longitude)) {
      unawaited(
        _animateTo(draft.latitude, draft.longitude, skipIdleReverse: true),
      );
      return;
    }

    if (_cameraTarget.latitude != _defaultMapCenter.latitude ||
        _cameraTarget.longitude != _defaultMapCenter.longitude) {
      unawaited(
        _animateTo(
          _cameraTarget.latitude,
          _cameraTarget.longitude,
          skipIdleReverse: true,
        ),
      );
    }
  }

  void _onCameraMove(CameraPosition position) {
    _cameraTarget = position.target;
  }

  void _onCameraIdle() {
    if (_mapState != MapDisplayState.interactive) return;
    if (_skipNextIdleReverse) {
      _skipNextIdleReverse = false;
      return;
    }

    _idleReverseDebounce?.cancel();
    final target = _cameraTarget;
    _idleReverseDebounce = Timer(
      const Duration(milliseconds: _idleReverseDebounceMs),
      () => _reverseGeocodeAt(target),
    );
  }

  void _onSearchChanged(String value) {
    if (_suppressSearch) {
      _suppressSearch = false;
      return;
    }

    _searchDebounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _searchLoading = false;
        _searchError = null;
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => _fetchSuggestions(value.trim()),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    _searchCancelToken?.cancel();
    final cancelToken = CancelToken();
    _searchCancelToken = cancelToken;

    setState(() {
      _searchLoading = true;
      _searchError = null;
    });

    try {
      final results = await ref.read(placesSearchServiceProvider).searchPlaces(
            query,
            sessionToken: _sessionToken,
            bias: _placesBiasOrNull(),
            cancelToken: cancelToken,
          );
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _suggestions = results;
        _searchLoading = false;
        if (results.isEmpty) _searchError = 'No places found';
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || !mounted) return;
      setState(() {
        _searchLoading = false;
        _suggestions = [];
        _searchError = 'Could not load suggestions';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchLoading = false;
        _suggestions = [];
        _searchError = 'Could not load suggestions';
      });
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion place) async {
    setState(() {
      _actionError = null;
      _selectingPlaceId = place.placeId;
    });

    try {
      var resolved = place;
      if (!place.hasValidCoordinates) {
        if (place.placeId.isEmpty) {
          setState(() {
            _actionError = 'Could not resolve map pin for this place';
          });
          return;
        }

        final details = await ref
            .read(placesSearchServiceProvider)
            .fetchPlaceDetails(
              place.placeId,
              sessionToken: _sessionToken,
            );
        if (!mounted) return;
        if (details == null || !details.hasValidCoordinates) {
          setState(() {
            _actionError = 'Could not resolve map pin for this place';
          });
          return;
        }
        resolved = details;
      }

      _rotateSessionToken();
      final selection = SalonLocationSelection.fromPlace(resolved);
      _suppressSearch = true;
      _searchController.text = selection.displayLabel;
      _searchFocus.unfocus();
      _applyDraft(selection, moveCamera: true, skipIdleReverse: true);
      setState(() {
        _suggestions = [];
        _searchError = null;
        _actionError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _actionError = 'Could not resolve map pin for this place';
      });
    } finally {
      if (mounted) setState(() => _selectingPlaceId = null);
    }
  }

  Future<void> _useCurrentLocation() async {
    await _goToDeviceLocation(showErrors: true, reverseGeocode: true);
  }

  Future<void> _reverseGeocodeAt(
    LatLng position, {
    bool showErrors = true,
  }) async {
    _reverseCancelToken?.cancel();
    final cancelToken = CancelToken();
    _reverseCancelToken = cancelToken;
    final requestId = ++_reverseRequestId;

    setState(() {
      _reverseGeocoding = true;
      if (showErrors) _actionError = null;
    });

    try {
      final reversed = await reverseGeocodeSalonLocation(
        position.latitude,
        position.longitude,
        placesService: ref.read(placesSearchServiceProvider),
        cancelToken: cancelToken,
      );

      if (!mounted || requestId != _reverseRequestId) return;

      if (reversed == null || !reversed.isComplete) {
        setState(() {
          _reverseGeocoding = false;
          if (showErrors) {
            _actionError = 'Could not resolve address for this pin';
          }
        });
        return;
      }

      final selection = reversed.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _draft = selection;
        _cameraTarget = position;
        _pendingCameraTarget = position;
        _reverseGeocoding = false;
        _actionError = null;
      });
      _suppressSearch = true;
      _searchController.text = selection.displayLabel;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || !mounted || requestId != _reverseRequestId) {
        return;
      }
      setState(() {
        _reverseGeocoding = false;
        if (showErrors) {
          _actionError = 'Could not resolve address for this pin';
        }
      });
    } catch (_) {
      if (!mounted || requestId != _reverseRequestId) return;
      setState(() {
        _reverseGeocoding = false;
        if (showErrors) {
          _actionError = 'Could not resolve address for this pin';
        }
      });
    }
  }

  void _confirm() {
    final draft = _draft;
    if (draft == null || !draft.isComplete) {
      setState(() => _actionError = 'Search and select your salon location');
      return;
    }
    Navigator.pop(context, draft.confirmed());
  }

  void _clearSearch() {
    _searchController.clear();
    _searchCancelToken?.cancel();
    setState(() {
      _suggestions = [];
      _searchError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canConfirm =
        !_initializingLocation && _draft?.isComplete == true;
    final showSuggestions = !_initializingLocation &&
        _mapState != MapDisplayState.unavailable &&
        _suggestions.isNotEmpty;

    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Set salon location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              enabled: !_initializingLocation,
              onChanged: _onSearchChanged,
              style: TextStyle(color: colors.textPrimary),
              decoration: AppDecorations.inputDecoration(
                context,
                label: 'Search salon location',
                hint: 'Area, street, or landmark',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: _clearSearch,
                          )
                        : null,
              ),
            ),
          ),
          if (_searchError != null &&
              _suggestions.isEmpty &&
              !_searchLoading) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                _searchError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _mapState == MapDisplayState.unavailable
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        _FallbackPanel(
                          suggestions: _suggestions,
                          draft: _draft,
                          selectingPlaceId: _selectingPlaceId,
                          onSelect: _selectSuggestion,
                          onUseCurrentLocation: (_gpsLoading ||
                                  _initializingLocation)
                              ? null
                              : _useCurrentLocation,
                          gpsLoading: _gpsLoading || _initializingLocation,
                        ),
                        if (_initializingLocation)
                          const Positioned.fill(
                            child: _LocationInitOverlay(),
                          ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _OwnerLocationMapView(
                            initialTarget: _cameraTarget,
                            onMapCreated: _onMapCreated,
                            onCameraMove: _onCameraMove,
                            onCameraIdle: _onCameraIdle,
                          ),
                          const IgnorePointer(child: _FixedCenterPin()),
                          if (_mapState == MapDisplayState.loading)
                            const Positioned.fill(child: _MapSkeleton()),
                          if (_reverseGeocoding && !_initializingLocation)
                            const Positioned(
                              top: 12,
                              right: 12,
                              child: _LoadingChip(label: 'Updating address…'),
                            ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: _CurrentLocationFab(
                              loading: _gpsLoading,
                              onTap: (_gpsLoading || _initializingLocation)
                                  ? null
                                  : _useCurrentLocation,
                            ),
                          ),
                          if (showSuggestions)
                            Positioned(
                              left: 12,
                              right: 12,
                              top: 12,
                              child: _SuggestionsList(
                                suggestions: _suggestions,
                                selectingPlaceId: _selectingPlaceId,
                                onSelect: _selectSuggestion,
                                maxHeight: 200,
                              ),
                            ),
                          if (_initializingLocation)
                            const Positioned.fill(
                              child: _LocationInitOverlay(),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
          if (_mapState == MapDisplayState.interactive) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Move the map to adjust the pin',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
          ],
          if (_lastGpsFailure != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: LocationErrorHint(failure: _lastGpsFailure),
            ),
          ],
          if (_actionError != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                _actionError!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_draft != null) _SelectedPreview(selection: _draft!),
                const SizedBox(height: 12),
                PremiumButton(
                  label: 'Confirm location',
                  variant: PremiumButtonVariant.accent,
                  onPressed: canConfirm ? _confirm : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns [GoogleMap] and only rebuilds when [initialTarget] identity for first
/// frame matters — camera updates go through the controller, not widget rebuilds.
class _OwnerLocationMapView extends StatefulWidget {
  const _OwnerLocationMapView({
    required this.initialTarget,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCameraIdle,
  });

  final LatLng initialTarget;
  final MapCreatedCallback onMapCreated;
  final CameraPositionCallback onCameraMove;
  final VoidCallback onCameraIdle;

  @override
  State<_OwnerLocationMapView> createState() => _OwnerLocationMapViewState();
}

class _OwnerLocationMapViewState extends State<_OwnerLocationMapView> {
  late final CameraPosition _initialCamera;

  @override
  void initState() {
    super.initState();
    final hasPin = widget.initialTarget.latitude != _defaultMapCenter.latitude ||
        widget.initialTarget.longitude != _defaultMapCenter.longitude;
    _initialCamera = CameraPosition(
      target: widget.initialTarget,
      zoom: hasPin ? 16 : 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: _initialCamera,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      onMapCreated: widget.onMapCreated,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      markers: const <Marker>{},
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
}

class _FixedCenterPin extends StatelessWidget {
  const _FixedCenterPin();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        // Offset so the pin tip sits on the map center.
        padding: const EdgeInsets.only(bottom: 36),
        child: Icon(
          Icons.location_on_rounded,
          size: 48,
          color: AppColors.accent,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({
    required this.suggestions,
    required this.onSelect,
    this.selectingPlaceId,
    this.maxHeight = 220,
  });

  final List<PlaceSuggestion> suggestions;
  final ValueChanged<PlaceSuggestion> onSelect;
  final String? selectingPlaceId;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      color: colors.surface,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: AppDecorations.glass(context, radius: 14),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: suggestions.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: colors.glassBorder.withValues(alpha: 0.5),
          ),
          itemBuilder: (context, index) {
            final place = suggestions[index];
            final subtitle = place.subtitleText;
            final isSelecting = selectingPlaceId == place.placeId;
            return ListTile(
              dense: true,
              leading: Icon(
                Icons.location_on_outlined,
                color: AppColors.accent.withValues(alpha: 0.9),
                size: 22,
              ),
              title: Text(
                place.titleText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: subtitle.isNotEmpty
                  ? Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    )
                  : null,
              trailing: isSelecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: isSelecting ? null : () => onSelect(place),
            );
          },
        ),
      ),
    );
  }
}

class _FallbackPanel extends StatelessWidget {
  const _FallbackPanel({
    required this.suggestions,
    required this.draft,
    required this.onSelect,
    required this.onUseCurrentLocation,
    required this.gpsLoading,
    this.selectingPlaceId,
  });

  final List<PlaceSuggestion> suggestions;
  final SalonLocationSelection? draft;
  final ValueChanged<PlaceSuggestion> onSelect;
  final VoidCallback? onUseCurrentLocation;
  final bool gpsLoading;
  final String? selectingPlaceId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: AppDecorations.glass(context, radius: 18),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.map_outlined,
                  color: AppColors.warning.withValues(alpha: 0.9),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Map unavailable — you can still search and confirm your salon address.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PremiumButton(
            label: 'Use current location',
            icon: Icons.my_location_rounded,
            loading: gpsLoading,
            variant: PremiumButtonVariant.ghost,
            onPressed: onUseCurrentLocation,
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Suggestions',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _SuggestionsList(
                suggestions: suggestions,
                selectingPlaceId: selectingPlaceId,
                onSelect: onSelect,
                maxHeight: double.infinity,
              ),
            ),
          ] else ...[
            const Spacer(),
            Text(
              'Search for your salon area above, then pick a suggestion to continue.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const Spacer(),
          ],
          if (draft != null) ...[
            const SizedBox(height: 12),
            _SelectedPreview(selection: draft!),
          ],
        ],
      ),
    );
  }
}

class _SelectedPreview extends StatelessWidget {
  const _SelectedPreview({required this.selection});

  final SalonLocationSelection selection;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final detail = selection.detailLine;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.glass(context, radius: 14, elevated: false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.place_rounded,
            color: AppColors.accent.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selection.displayLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  formatCoordinatesLabel(
                    selection.latitude,
                    selection.longitude,
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      color: colors.surfaceElevated,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading map…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationInitOverlay extends StatelessWidget {
  const _LocationInitOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 14),
              Text(
                'Finding your location…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'This may take a few seconds if GPS was off',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationFab extends StatelessWidget {
  const _CurrentLocationFab({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 22),
          ),
        ),
      ),
    );
  }
}
