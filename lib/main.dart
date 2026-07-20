import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/app.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/notifications/firebase_background_handler.dart';
import 'package:saloon_booking/firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    PaintingBinding.instance.imageCache
      ..maximumSize = 100
      ..maximumSizeBytes = 50 << 20;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await CrashReporting.initialize();
    CrashReporting.installGlobalHandlers();

    runApp(Root(key: Root.rootKey));
  }, (error, stack) {
    unawaited(
      CrashReporting.recordError(error, stack, fatal: true, reason: 'zone'),
    );
  });
}

/// Recreates [ProviderScope] on logout so cached user-scoped state is cleared.
class Root extends StatefulWidget {
  const Root({super.key});

  static final rootKey = GlobalKey<_RootState>();

  static void restartApp() {
    rootKey.currentState?.restart();
  }

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  Key _scopeKey = UniqueKey();

  void restart() {
    setState(() => _scopeKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: _scopeKey,
      child: const SalonApp(),
    );
  }
}
