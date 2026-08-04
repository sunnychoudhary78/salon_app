import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';

/// Duration without touch input before the app is considered idle.
const userIdleTimeout = Duration(minutes: 3);

class UserIdle extends Notifier<bool> {
  Timer? _idleTimer;

  @override
  bool build() {
    ref.onDispose(() => _idleTimer?.cancel());
    _scheduleIdleCheck();
    return false;
  }

  void recordActivity() {
    if (state) {
      state = false;
      CrashReporting.breadcrumb('user_idle_exit');
    }
    _scheduleIdleCheck();
  }

  void _scheduleIdleCheck() {
    _idleTimer?.cancel();
    _idleTimer = Timer(userIdleTimeout, () {
      if (!state) {
        state = true;
        // Keep visible images alive. Evicting them here caused every image on
        // the current screen to decode again on the first interaction.
        CrashReporting.breadcrumb('user_idle_enter');
      }
    });
  }
}

final userIdleProvider = NotifierProvider<UserIdle, bool>(UserIdle.new);

/// Debug-only timestamp of the last successful [AutoRefresh] run.
class LastAutoRefreshAt extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void mark() => state = DateTime.now();
}

final lastAutoRefreshAtProvider =
    NotifierProvider<LastAutoRefreshAt, DateTime?>(LastAutoRefreshAt.new);
