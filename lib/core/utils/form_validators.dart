import 'package:flutter/material.dart';

const int kNotesMaxLength = 500;
const int kReviewMaxLength = 1000;
const int kNameMinLength = 2;
const double kPriceMax = 1000000;
const int kDurationMinMinutes = 5;
const int kDurationMaxMinutes = 480;

final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
);

final RegExp _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

final RegExp _upiRegex = RegExp(
  r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z][a-zA-Z0-9.\-]{2,64}$',
);

/// Indian GSTIN: 15 chars (simplified pattern).
final RegExp _gstinRegex = RegExp(
  r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
);

void showFormDisabledMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String? validateRequiredName(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return 'Name is required';
  if (trimmed.length < kNameMinLength) {
    return 'Enter at least $kNameMinLength characters';
  }
  return null;
}

String? validateOptionalEmail(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return null;
  if (!_emailRegex.hasMatch(trimmed)) return 'Enter a valid email';
  return null;
}

String? validateRequiredEmail(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return 'Email is required';
  if (!_emailRegex.hasMatch(trimmed)) return 'Enter a valid email';
  return null;
}

String? validatePrice(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return 'Price is required';
  final parsed = double.tryParse(trimmed);
  if (parsed == null) return 'Enter a valid price';
  if (parsed <= 0) return 'Price must be greater than 0';
  if (parsed > kPriceMax) return 'Price is too high';
  return null;
}

String? validateDiscountPrice(String? value, {required double? price}) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return null;
  final parsed = double.tryParse(trimmed);
  if (parsed == null) return 'Enter a valid final price after discount';
  if (parsed <= 0) return 'Final price after discount must be greater than 0';
  if (price == null || price <= 0) {
    return 'Enter a valid price first';
  }
  if (parsed >= price) {
    return 'Final price after discount must be less than the original price';
  }
  return null;
}

String? validateDurationMinutes(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return 'Duration is required';
  final parsed = int.tryParse(trimmed);
  if (parsed == null) return 'Enter duration in minutes';
  if (parsed < kDurationMinMinutes || parsed > kDurationMaxMinutes) {
    return 'Duration must be $kDurationMinMinutes–$kDurationMaxMinutes minutes';
  }
  return null;
}

String? validateIfsc(String? value) {
  final trimmed = (value ?? '').trim().toUpperCase();
  if (trimmed.isEmpty) return 'IFSC is required';
  if (!_ifscRegex.hasMatch(trimmed)) {
    return 'Enter a valid IFSC (e.g. SBIN0001234)';
  }
  return null;
}

String? validateAccountNumber(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Account number is required';
  if (digits.length < 9 || digits.length > 18) {
    return 'Enter a valid account number (9–18 digits)';
  }
  return null;
}

String? validateOptionalUpi(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return null;
  if (!_upiRegex.hasMatch(trimmed)) {
    return 'Enter a valid UPI ID (e.g. name@bank)';
  }
  return null;
}

String? validateOptionalNotes(
  String? value, {
  int maxLength = kNotesMaxLength,
}) {
  final text = value ?? '';
  if (text.length > maxLength) {
    return 'Keep notes under $maxLength characters';
  }
  return null;
}

String? validateGstOptional(String? value) {
  final trimmed = (value ?? '').trim().toUpperCase();
  if (trimmed.isEmpty) return null;
  if (!_gstinRegex.hasMatch(trimmed)) {
    return 'Enter a valid 15-character GSTIN';
  }
  return null;
}

String? validateReviewComment(
  String? value, {
  required int rating,
  int? staffRating,
}) {
  final trimmed = (value ?? '').trim();
  if (trimmed.length > kReviewMaxLength) {
    return 'Keep review under $kReviewMaxLength characters';
  }
  final lowRating = rating <= 2 || (staffRating != null && staffRating <= 2);
  if (lowRating && trimmed.isEmpty) {
    return 'Please add a comment for low ratings';
  }
  return null;
}

String? validateAccountHolderName(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) return 'Account holder name is required';
  if (trimmed.length < kNameMinLength) {
    return 'Enter at least $kNameMinLength characters';
  }
  return null;
}
