import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/auth/presentation/utils/otp_sms_listener.dart';
import 'package:saloon_booking/features/profile/data/services/profile_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/auth_scaffold.dart';
import 'package:saloon_booking/shared/widgets/otp_pin_input.dart';
import 'package:saloon_booking/shared/widgets/otp_sms_retriever.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class ChangePhoneOtpScreen extends ConsumerStatefulWidget {
  const ChangePhoneOtpScreen({
    super.key,
    required this.phone,
    this.isOwnerMode = false,
  });

  final String phone;
  final bool isOwnerMode;

  @override
  ConsumerState<ChangePhoneOtpScreen> createState() =>
      _ChangePhoneOtpScreenState();
}

class _ChangePhoneOtpScreenState extends ConsumerState<ChangePhoneOtpScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _smsRetriever = OtpSmsRetriever();
  Timer? _timer;
  int _secondsLeft = 300;
  bool _loading = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
    OtpSmsListener.instance.activateSession();
    OtpSmsListener.instance.startBackgroundListen();
    unawaited(OtpSmsListener.instance.logAppSignature());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _otpFocusNode.requestFocus();
      _applyPendingCodeIfAny();
    });
  }

  void _applyPendingCodeIfAny() {
    final pending = OtpSmsListener.instance.takePendingCode();
    if (pending == null) return;
    _otpController.text = pending;
    if (!_loading) _verify();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(OtpSmsListener.instance.stopSession());
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 300);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else if (mounted) {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _maskedPhone {
    final digits = widget.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return widget.phone;
    return '******${digits.substring(digits.length - 4)}';
  }

  String get _editProfileRoute => widget.isOwnerMode
      ? RoutePaths.ownerEditProfile
      : RoutePaths.customerEditProfile;

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 240) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref
          .read(profileActionsProvider)
          .requestPhoneChangeOtp(phone: widget.phone);
      _startTimer();
      OtpSmsListener.instance.activateSession();
      OtpSmsListener.instance.startBackgroundListen();
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    if (_secondsLeft <= 0) {
      setState(() => _error = 'OTP expired. Please resend.');
      return;
    }
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(profileActionsProvider)
          .verifyPhoneChangeOtp(phone: widget.phone, otp: otp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number updated')),
      );
      context.go(_editProfileRoute);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft <= 240;

    return AuthScaffold(
      headline: 'Verify new number',
      subtitle: 'Sent to $_maskedPhone',
      onBack: () => context.pop(),
      child: AnimatedEntrance(
        style: EntranceStyle.scaleIn,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _secondsLeft > 0
                  ? 'Expires in ${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}'
                  : 'Code expired',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _secondsLeft > 0
                    ? context.appColors.textSecondary
                    : AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Center(
              child: OtpPinInput(
                controller: _otpController,
                focusNode: _otpFocusNode,
                smsRetriever: _smsRetriever,
                enabled: !_loading && _secondsLeft > 0,
                hasError: _error != null,
                onCompleted: (_) => _verify(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 28),
            PremiumButton(
              label: 'Verify & update',
              loading: _loading,
              onPressed: _loading ? null : _verify,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: canResend && !_resending ? _resend : null,
              child: Text(
                _resending
                    ? 'Sending…'
                    : canResend
                    ? 'Resend OTP'
                    : 'Resend available soon',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
