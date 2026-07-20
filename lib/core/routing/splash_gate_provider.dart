import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';

/// After [splashGateTimeout], the router stops waiting on auth/onboarding loading.
const splashGateTimeout = Duration(seconds: 10);

class SplashGate extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer(splashGateTimeout, () {
      if (!state) {
        CrashReporting.breadcrumb('splash_gate_timeout');
        state = true;
      }
    });
    return false;
  }
}

final splashGateProvider = NotifierProvider<SplashGate, bool>(SplashGate.new);
