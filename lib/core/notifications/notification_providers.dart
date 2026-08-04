import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/notifications/notification_service.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';

/// Side-effect notifier for FCM registration. Uses [ref.listen] only — never
/// [ref.watch] — so auth changes do not rebuild [SalonApp].
class NotificationLifecycle extends Notifier<void> {
  var _handledSession = false;
  var _registering = false;

  @override
  void build() {
    ref.listen(authProvider, (previous, next) {
      if (next.isLoading) return;

      final wasLoggedIn = previous?.value != null;
      final isLoggedIn = next.value != null;

      if (!wasLoggedIn && isLoggedIn) {
        _register();
      }

      if (wasLoggedIn && !isLoggedIn) {
        _handledSession = false;
      }
    });

    Future.microtask(_bootstrapIfNeeded);
  }

  Future<void> _bootstrapIfNeeded() async {
    if (_handledSession) return;
    final auth = ref.read(authProvider);
    if (!auth.isLoading && auth.value != null) {
      await _register();
    }
  }

  Future<void> _register() async {
    if (_registering) return;
    _registering = true;
    try {
      final ok = await ref.read(notificationServiceProvider).onAuthenticated();
      _handledSession = ok;
      ref.invalidate(unreadCountProvider);
    } finally {
      _registering = false;
    }
  }
}

final notificationLifecycleProvider =
    NotifierProvider<NotificationLifecycle, void>(NotificationLifecycle.new);
