import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:saloon_booking/app.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/notifications/firebase_background_handler.dart';
import 'package:saloon_booking/firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      final startupStopwatch = Stopwatch()..start();
      WidgetsFlutterBinding.ensureInitialized();

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final imagePickerImplementation = ImagePickerPlatform.instance;
        if (imagePickerImplementation is ImagePickerAndroid) {
          imagePickerImplementation.useAndroidPhotoPicker = true;
        }
      }

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      PaintingBinding.instance.imageCache
        ..maximumSize = 100
        ..maximumSizeBytes = 50 << 20;

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      CrashReporting.installGlobalHandlers();

      runApp(Root(key: Root.rootKey));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startupStopwatch.stop();
        CrashReporting.log(
          'startup_first_frame: ${startupStopwatch.elapsedMilliseconds}ms',
        );
        unawaited(CrashReporting.initialize());
      });
    },
    (error, stack) {
      unawaited(
        CrashReporting.recordError(error, stack, fatal: true, reason: 'zone'),
      );
    },
  );
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
    return ProviderScope(key: _scopeKey, child: const SalonApp());
  }
}
