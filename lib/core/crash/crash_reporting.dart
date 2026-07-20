import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Central crash logging and breadcrumb helpers.
class CrashReporting {
  CrashReporting._();

  static FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  static Future<void> initialize() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  static void installGlobalHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _crashlytics.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[CrashReporting] $message');
    }
    _crashlytics.log(message);
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (kDebugMode) {
      debugPrint('[CrashReporting] error: $error');
      if (stack != null) debugPrint(stack.toString());
    }
    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  static void breadcrumb(String action) => log('breadcrumb: $action');
}

/// Runs [computation] with a timeout; on timeout invokes [onTimeout] or rethrows.
Future<T> withStorageTimeout<T>(
  Future<T> computation, {
  Duration timeout = const Duration(seconds: 5),
  T Function()? onTimeout,
  String? label,
}) async {
  try {
    return await computation.timeout(timeout);
  } on TimeoutException catch (e) {
    CrashReporting.log(
      'Storage timeout${label != null ? ' ($label)' : ''}: $e',
    );
    if (onTimeout != null) return onTimeout();
    rethrow;
  }
}
