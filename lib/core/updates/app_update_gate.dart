import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/ui/root_scaffold_messenger.dart';
import 'package:saloon_booking/core/updates/app_update_policy.dart';
import 'package:saloon_booking/core/updates/play_store_update_service.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_dialog.dart';

/// Checks Play for an app update after splash and prompts with CATCHY dialogs.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({
    super.key,
    required this.child,
    required this.currentLocation,
    this.routeListenable,
    this.service,
    this.prefs,
    this.now,
    this.isSupportedPlatform,
  });

  final Widget child;
  final String Function() currentLocation;
  final Listenable? routeListenable;
  final PlayStoreUpdateService? service;
  final Future<SharedPreferences> Function()? prefs;
  final DateTime Function()? now;
  final bool Function()? isSupportedPlatform;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  bool _prompting = false;
  bool _checkedAfterSplash = false;

  PlayStoreUpdateService get _service =>
      widget.service ?? const PlayCoreUpdateService();

  bool get _supported =>
      widget.isSupportedPlatform?.call() ?? PlayCoreUpdateService.isSupported;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.routeListenable?.addListener(_onRoute);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_maybeCheck()),
    );
  }

  @override
  void didUpdateWidget(AppUpdateGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeListenable != widget.routeListenable) {
      oldWidget.routeListenable?.removeListener(_onRoute);
      widget.routeListenable?.addListener(_onRoute);
    }
  }

  @override
  void dispose() {
    widget.routeListenable?.removeListener(_onRoute);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onRoute() => unawaited(_maybeCheck());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeCheck(fromResume: true));
    }
  }

  Future<SharedPreferences> _prefs() {
    return (widget.prefs ?? SharedPreferences.getInstance)();
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  Future<void> _maybeCheck({bool fromResume = false}) async {
    if (!mounted || _prompting || !_supported) return;

    final location = widget.currentLocation();
    if (location.isEmpty || location == RoutePaths.splash) return;

    final check = await _service.check();
    if (!mounted) return;

    if (check.alreadyDownloaded) {
      await _promptRestart();
      return;
    }

    if (_checkedAfterSplash && !fromResume) return;
    _checkedAfterSplash = true;

    if (!fromResume) {
      final prefs = await _prefs();
      final snoozed = isUpdateSnoozed(
        prefs.getInt(updatePromptSnoozeKey),
        _now(),
      );
      if (!shouldPromptForAvailableUpdate(
        snoozed: snoozed,
        updateAvailable: check.updateAvailable,
      )) {
        return;
      }
      await _promptAvailable(check);
    }
  }

  Future<void> _promptAvailable(PlayStoreUpdateCheck check) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    _prompting = true;
    try {
      final updateNow = await showPremiumDialog<bool>(
        context: ctx,
        barrierDismissible: false,
        title: 'New version available',
        subtitle:
            'A newer version of CATCHY is on the Play Store. Update now for the latest fixes and features.',
        confirmLabel: 'Update now',
        cancelLabel: 'Later',
        confirmVariant: PremiumButtonVariant.accent,
        content: Icon(
          Icons.system_update_alt_rounded,
          size: 48,
          color: ctx.appColors.accent,
        ),
      );
      if (!mounted) return;

      if (updateNow != true) {
        final prefs = await _prefs();
        await prefs.setInt(
          updatePromptSnoozeKey,
          _now().millisecondsSinceEpoch,
        );
        return;
      }

      if (!check.flexibleAllowed) {
        await _service.openStoreListing();
        return;
      }

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Downloading update…')),
      );

      final result = await _service.startFlexibleUpdate();
      if (!mounted) return;
      switch (result) {
        case FlexibleUpdateStartResult.downloaded:
          await _promptRestart();
        case FlexibleUpdateStartResult.denied:
          return;
        case FlexibleUpdateStartResult.failed:
          await _service.openStoreListing();
      }
    } finally {
      _prompting = false;
    }
  }

  Future<void> _promptRestart() async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    _prompting = true;
    try {
      final restart = await showPremiumDialog<bool>(
        context: ctx,
        barrierDismissible: false,
        title: 'Restart to finish update',
        subtitle:
            'The new version has downloaded. Restart CATCHY to install it.',
        confirmLabel: 'Restart now',
        showCancel: false,
        confirmVariant: PremiumButtonVariant.accent,
      );
      if (restart == true) {
        await _service.completeFlexibleUpdate();
      }
    } finally {
      _prompting = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
