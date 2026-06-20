import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:saloon_booking/core/utils/otp_utils.dart';
import 'package:smart_auth/smart_auth.dart';

/// Coordinates Android SMS listening across login and OTP verify screens.
class OtpSmsListener {
  OtpSmsListener._();

  static final OtpSmsListener instance = OtpSmsListener._();

  final SmartAuth _smartAuth = SmartAuth.instance;
  final StreamController<String> _codeController =
      StreamController<String>.broadcast();

  String? _pendingCode;
  bool _sessionActive = false;
  bool _loopRunning = false;

  void activateSession() {
    if (!Platform.isAndroid) return;
    _sessionActive = true;
  }

  /// Start listening before OTP screen opens (call after OTP API success).
  void startBackgroundListen() {
    if (!Platform.isAndroid || !_sessionActive || _loopRunning) return;
    _loopRunning = true;
    unawaited(_listenLoop());
  }

  Future<void> _listenLoop() async {
    while (_sessionActive) {
      try {
        final res = await _smartAuth.getSmsWithUserConsentApi();
        if (!_sessionActive) break;
        if (res.hasData && res.data?.code != null) {
          final otp = extractOtp(res.data!.code);
          if (otp != null) {
            _pendingCode = otp;
            if (!_codeController.isClosed) {
              _codeController.add(otp);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('OtpSmsListener: $e');
        }
        break;
      }
    }
    _loopRunning = false;
  }

  String? takePendingCode() {
    final code = _pendingCode;
    _pendingCode = null;
    return code;
  }

  /// Used by [OtpSmsRetriever] / Pinput — returns pending code or waits for next SMS.
  Future<String?> waitForCode() async {
    if (!Platform.isAndroid) return null;

    final pending = takePendingCode();
    if (pending != null) return pending;

    if (!_sessionActive) return null;

    try {
      return await _codeController.stream.first.timeout(
        const Duration(minutes: 5),
      );
    } on TimeoutException {
      return null;
    }
  }

  Future<void> logAppSignature() async {
    if (!Platform.isAndroid || !kDebugMode) return;
    try {
      final result = await _smartAuth.getAppSignature();
      if (result.hasData) {
        debugPrint('SMS app hash: ${result.data}');
      }
    } catch (e) {
      debugPrint('SMS app hash error: $e');
    }
  }

  Future<void> stopSession() async {
    _sessionActive = false;
    _pendingCode = null;
    if (Platform.isAndroid) {
      await Future.wait([
        _smartAuth.removeUserConsentApiListener(),
        _smartAuth.removeSmsRetrieverApiListener(),
      ]);
    }
    _loopRunning = false;
  }
}
