import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';

class PremiumTextField extends StatelessWidget {
  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.enabled = true,
    this.underline = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final bool enabled;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      style: const TextStyle(color: Colors.white),
      decoration: AppDecorations.inputDecoration(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        underline: underline,
      ),
    );
  }
}
