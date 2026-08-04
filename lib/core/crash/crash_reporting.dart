import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Central crash logging and breadcrumb helpers.
class CrashReporting {
  CrashReporting._();

  static FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;
  static bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

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
    if (_isFirebaseReady) {
      _crashlytics.log(message);
    }
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
    if (_isFirebaseReady) {
      await _crashlytics.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
      );
    }
  }

  static void breadcrumb(String action) => log('breadcrumb: $action');

  /// Measures work that may affect responsiveness and records only slow runs.
  static T measure<T>(
    String operation,
    T Function() computation, {
    Duration slowThreshold = const Duration(milliseconds: 16),
  }) {
    final stopwatch = Stopwatch()..start();
    try {
      return computation();
    } finally {
      stopwatch.stop();
      if (stopwatch.elapsed >= slowThreshold) {
        log('slow_operation: $operation ${stopwatch.elapsedMilliseconds}ms');
      }
    }
  }

  /// Async counterpart to [measure], useful for lifecycle and refresh traces.
  static Future<T> measureAsync<T>(
    String operation,
    Future<T> Function() computation, {
    Duration slowThreshold = const Duration(milliseconds: 500),
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await computation();
    } finally {
      stopwatch.stop();
      if (stopwatch.elapsed >= slowThreshold) {
        log('slow_operation: $operation ${stopwatch.elapsedMilliseconds}ms');
      }
    }
  }
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
