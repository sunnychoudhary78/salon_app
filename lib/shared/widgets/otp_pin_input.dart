import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class OtpPinInput extends StatelessWidget {
  const OtpPinInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.hasError = false,
    this.smsRetriever,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool hasError;
  final SmsRetriever? smsRetriever;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.glassBorder),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: context.appColors.accent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: context.appColors.accent.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(
          color: context.appColors.accent.withValues(alpha: 0.6),
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.error),
      ),
    );

    return AutofillGroup(
      child: Pinput(
        length: 6,
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: true,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        submittedPinTheme: submittedPinTheme,
        followingPinTheme: defaultPinTheme,
        disabledPinTheme: defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration?.copyWith(
            color: colors.glassFill.withValues(alpha: 0.5),
          ),
        ),
        errorPinTheme: errorPinTheme,
        forceErrorState: hasError,
        separatorBuilder: (index) => const SizedBox(width: 8),
        hapticFeedbackType: HapticFeedbackType.lightImpact,
        onChanged: onChanged,
        onCompleted: onCompleted,
        smsRetriever: smsRetriever,
        cursor: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 20,
              height: 2,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.appColors.accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
