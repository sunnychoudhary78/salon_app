import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/settings/presentation/screens/legal_info_screen.dart';

enum LegalAcknowledgementKind { auth, booking }

class LegalAcknowledgement extends StatefulWidget {
  const LegalAcknowledgement.auth({
    super.key,
    this.textAlign = TextAlign.center,
  }) : kind = LegalAcknowledgementKind.auth;

  const LegalAcknowledgement.booking({
    super.key,
    this.textAlign = TextAlign.center,
  }) : kind = LegalAcknowledgementKind.booking;

  final LegalAcknowledgementKind kind;
  final TextAlign textAlign;

  @override
  State<LegalAcknowledgement> createState() => _LegalAcknowledgementState();
}

class _LegalAcknowledgementState extends State<LegalAcknowledgement> {
  late final TapGestureRecognizer _firstLink;
  late final TapGestureRecognizer _secondLink;

  @override
  void initState() {
    super.initState();
    _firstLink = TapGestureRecognizer()..onTap = _openFirst;
    _secondLink = TapGestureRecognizer()..onTap = _openSecond;
  }

  @override
  void dispose() {
    _firstLink.dispose();
    _secondLink.dispose();
    super.dispose();
  }

  void _openFirst() {
    LegalInfoScreen.open(context, kind: LegalInfoKind.terms);
  }

  void _openSecond() {
    LegalInfoScreen.open(
      context,
      kind: widget.kind == LegalAcknowledgementKind.auth
          ? LegalInfoKind.privacy
          : LegalInfoKind.refund,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.textMuted,
      height: 1.4,
    );
    final linkStyle = baseStyle?.copyWith(
      color: colors.accent,
      fontWeight: FontWeight.w600,
    );

    final secondLabel = widget.kind == LegalAcknowledgementKind.auth
        ? 'Privacy Policy'
        : 'Cancellation & Refund Policy';
    final lead = widget.kind == LegalAcknowledgementKind.auth
        ? 'By continuing, you agree to our '
        : 'By continuing, you acknowledge our ';

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: lead),
          TextSpan(
            text: 'Terms & Conditions',
            style: linkStyle,
            recognizer: _firstLink,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: secondLabel,
            style: linkStyle,
            recognizer: _secondLink,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}
