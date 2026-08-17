import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// In-app alert loop (sound + haptics) while the forced booking dialog is open.
class BookingAlertFeedback {
  BookingAlertFeedback._();

  static final BookingAlertFeedback instance = BookingAlertFeedback._();

  final AudioPlayer _player = AudioPlayer();
  Timer? _hapticTimer;
  bool _active = false;

  Future<void> start() async {
    if (_active) return;
    _active = true;

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1);
      await _player.play(AssetSource('sounds/booking_urgent.wav'));
    } catch (_) {
      // Sound is best-effort; haptics still run.
    }

    unawaited(HapticFeedback.heavyImpact());
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_active) return;
      unawaited(HapticFeedback.heavyImpact());
    });
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    _hapticTimer?.cancel();
    _hapticTimer = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
