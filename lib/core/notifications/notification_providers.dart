import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/notifications/notification_service.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/notifications/data/providers/notification_history_provider.dart';

final notificationLifecycleProvider = Provider<void>((ref) {
  var handledSession = false;

  ref.listen(authProvider, (previous, next) {
    if (next.isLoading) return;

    final wasLoggedIn = previous?.value != null;
    final isLoggedIn = next.value != null;

    if (!wasLoggedIn && isLoggedIn) {
      handledSession = true;
      ref.read(notificationServiceProvider).onAuthenticated();
      ref.invalidate(unreadCountProvider);
    }

    if (wasLoggedIn && !isLoggedIn) {
      handledSession = false;
    }
  });

  final auth = ref.watch(authProvider);
  if (!handledSession && !auth.isLoading && auth.value != null) {
    handledSession = true;
    Future.microtask(() {
      ref.read(notificationServiceProvider).onAuthenticated();
      ref.invalidate(unreadCountProvider);
    });
  }
});
