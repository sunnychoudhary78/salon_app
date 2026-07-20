import 'package:flutter/services.dart';

const int phoneDigitLength = 10;

String normalizePhoneDigits(String input) {
  return input.replaceAll(RegExp(r'\D'), '');
}

bool isValidPhoneDigits(String input) {
  return normalizePhoneDigits(input).length == phoneDigitLength;
}

String? validatePhoneDigits(String? value, {bool required = true}) {
  final digits = normalizePhoneDigits(value ?? '');
  if (digits.isEmpty) {
    return required ? 'Phone number is required' : null;
  }
  if (digits.length != phoneDigitLength) {
    return 'Enter a valid 10-digit phone number';
  }
  return null;
}

String? validateOptionalPhoneDigits(String? value) =>
    validatePhoneDigits(value, required: false);

List<TextInputFormatter> get phoneDigitInputFormatters => [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(phoneDigitLength),
];
