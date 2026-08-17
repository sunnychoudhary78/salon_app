import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/lifecycle/idle_debug_overlay.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_scope.dart';
import 'package:saloon_booking/core/network/session_expired_notifier.dart';
import 'package:saloon_booking/core/notifications/notification_providers.dart';
import 'package:saloon_booking/core/providers/user_data_invalidation.dart';
import 'package:saloon_booking/core/routing/app_router.dart';
import 'package:saloon_booking/core/theme/accent_palette.dart';
import 'package:saloon_booking/core/theme/accent_palette_provider.dart';
import 'package:saloon_booking/core/theme/app_theme.dart';
import 'package:saloon_booking/core/theme/theme_mode_provider.dart';
import 'package:saloon_booking/core/ui/root_scaffold_messenger.dart';
import 'package:saloon_booking/core/ui/system_ui_scope.dart';
import 'package:saloon_booking/core/updates/app_update_gate.dart';
import 'package:saloon_booking/core/utils/role_utils.dart';
import 'package:saloon_booking/features/auth/data/models/user_model.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/pending_booking_gate_lifecycle.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/pending_booking_gate_overlay.dart';

class SalonApp extends ConsumerStatefulWidget {
  const SalonApp({super.key});

  @override
  ConsumerState<SalonApp> createState() => _SalonAppState();
}

class _SalonAppState extends ConsumerState<SalonApp> {
  ProviderSubscription<AsyncValue<AuthState?>>? _authSubscription;
  ProviderSubscription<int>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(notificationLifecycleProvider);
      _authSubscription = ref.listenManual(authProvider, (previous, next) {
        invalidateOnUserIdChange(
          ref,
          previous?.value?.user.id,
          next.value?.user.id,
        );
      });
      _sessionExpiredSubscription = ref.listenManual(sessionExpiredProvider, (
        previous,
        next,
      ) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            duration: Duration(seconds: 4),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _sessionExpiredSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.dark;
    final storedPalette =
        ref.watch(accentPaletteProvider).value ?? AccentPalette.rose;
    final auth = ref.watch(authProvider).value;
    final accentPalette = AccentPalette.forSession(
      isOwner: auth != null && isSalonOwnerAccount(auth),
      stored: storedPalette,
    );

    return SystemUiScope(
      brightness: themeMode == ThemeMode.light
          ? Brightness.light
          : Brightness.dark,
      child: MaterialApp.router(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: AppConfig.appName,
        theme: AppTheme.lightFor(accentPalette),
        darkTheme: AppTheme.darkFor(accentPalette),
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return AppUpdateGate(
            currentLocation: () {
              try {
                return router.routerDelegate.currentConfiguration.uri.path;
              } catch (_) {
                return '';
              }
            },
            routeListenable: router.routerDelegate,
            child: PendingBookingGateLifecycle(
              child: UserActivityScope(
                child: IdleDebugOverlay(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child ?? const SizedBox.shrink(),
                      const PendingBookingGateOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
