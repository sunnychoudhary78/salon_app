import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/utils/phone_validation.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/auth/presentation/utils/otp_sms_listener.dart';
import 'package:saloon_booking/features/profile/data/services/profile_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/auth_scaffold.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key, this.isOwnerMode = false});

  final bool isOwnerMode;

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _otpRoute => widget.isOwnerMode
      ? RoutePaths.ownerChangePhoneOtp
      : RoutePaths.customerChangePhoneOtp;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = normalizePhoneDigits(_phoneController.text);
    final current = ref.read(authProvider).value?.user.phone;
    if (current != null && normalizePhoneDigits(current) == phone) {
      setState(() => _error = 'This is already your current phone number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(profileActionsProvider)
          .requestPhoneChangeOtp(phone: phone);
      if (!mounted) return;
      OtpSmsListener.instance.activateSession();
      OtpSmsListener.instance.startBackgroundListen();
      context.push(_otpRoute, extra: phone);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhone = ref.watch(authProvider).value?.user.phone;

    return AuthScaffold(
      headline: 'Change phone number',
      subtitle: currentPhone != null && currentPhone.isNotEmpty
          ? 'Current: $currentPhone'
          : 'Verify a new number with OTP',
      onBack: () => context.pop(),
      child: AnimatedEntrance(
        style: EntranceStyle.scaleIn,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your new 10-digit mobile number. We will send an OTP to verify it.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              PremiumTextField(
                controller: _phoneController,
                label: 'New phone number',
                keyboardType: TextInputType.phone,
                inputFormatters: phoneDigitInputFormatters,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: validatePhoneDigits,
                enabled: !_loading,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              PremiumButton(
                label: 'Send OTP',
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
