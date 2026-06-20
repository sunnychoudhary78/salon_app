import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/notifications/notification_providers.dart';
import 'package:saloon_booking/core/routing/app_router.dart';
import 'package:saloon_booking/core/theme/app_theme.dart';

class SalonApp extends ConsumerWidget {
  const SalonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationLifecycleProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
