/// Safe JSON field accessors that avoid cast crashes on unexpected nulls.
String requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    throw FormatException('Missing required field: $key');
  }
  return value.toString();
}

String? optionalString(Map<String, dynamic>? json, String key) {
  if (json == null) return null;
  final value = json[key];
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}
