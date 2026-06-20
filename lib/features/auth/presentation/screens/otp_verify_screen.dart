import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/role_utils.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/auth/presentation/utils/otp_sms_listener.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/auth_scaffold.dart';
import 'package:saloon_booking/shared/widgets/otp_pin_input.dart';
import 'package:saloon_booking/shared/widgets/otp_sms_retriever.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
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

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 240) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).requestOtp(widget.phone);
      _startTimer();
      OtpSmsListener.instance.activateSession();
      OtpSmsListener.instance.startBackgroundListen();
    } on DioException catch (e) {
      setState(() => _error = e.apiException.message);
    } catch (e) {
      setState(() => _error = e.toString());
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
      final result = await ref.read(authProvider.notifier).verifyOtp(
            widget.phone,
            otp,
          );
      if (!mounted) return;

      if (result.isNewUser) {
        context.go(RoutePaths.completeProfile);
      } else {
        final auth = ref.read(authProvider).value;
        final home = auth != null && isSalonOwnerAccount(auth)
            ? RoutePaths.ownerDashboard
            : RoutePaths.customerHome;
        context.go(home);
      }
    } on DioException catch (e) {
      setState(() => _error = e.apiException.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft <= 240;

    return AuthScaffold(
      headline: 'Verify your number',
      subtitle: 'Sent to $_maskedPhone',
      onBack: () => context.pop(),
      child: AnimatedEntrance(
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
                        ? AppColors.textSecondary
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
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onCompleted: (_) {
                  if (!_loading) _verify();
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
            const SizedBox(height: 32),
            PremiumButton(
              label: 'Verify',
              loadingLabel: 'Verifying...',
              variant: PremiumButtonVariant.accent,
              loading: _loading,
              icon: Icons.verified_rounded,
              onPressed: _secondsLeft > 0 ? _verify : null,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: canResend && !_resending ? _resend : null,
              child: _resending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      canResend
                          ? 'Resend OTP'
                          : 'Resend available in ${(_secondsLeft - 240).clamp(0, 60)}s',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
