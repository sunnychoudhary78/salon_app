/// Extracts a 6-digit OTP from raw SMS or plugin output.
String? extractOtp(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return RegExp(r'\d{6}').firstMatch(raw)?.group(0);
}
