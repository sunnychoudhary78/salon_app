class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.label,
    required this.address,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.formattedAddress = '',
    this.locality = '',
    this.postalCode = '',
    this.mainText = '',
    this.secondaryText = '',
  });

  final String placeId;
  final String label;
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String locality;
  final String postalCode;
  final String mainText;
  final String secondaryText;

  String get street => address;

  String get titleText {
    final main = mainText.trim();
    if (main.isNotEmpty) return main;
    final formatted = formattedAddress.trim();
    if (formatted.isNotEmpty) return formatted;
    return label.trim();
  }

  String get subtitleText {
    final secondary = secondaryText.trim();
    if (secondary.isNotEmpty) return secondary;
    final parts = [
      locality.trim(),
      city.trim(),
      state.trim(),
      postalCode.trim(),
    ].where((s) => s.isNotEmpty);
    return parts.join(', ');
  }

  bool get hasValidCoordinates =>
      latitude != 0 && longitude != 0 && latitude.isFinite && longitude.isFinite;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final formatted = (json['formatted_address'] as String? ?? '').trim();
    final label = (json['label'] as String? ?? '').trim();
    final street = (json['street'] as String? ?? json['address'] as String? ?? '')
        .trim();
    return PlaceSuggestion(
      placeId: json['place_id']?.toString() ?? '',
      label: label,
      address: street,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      formattedAddress: formatted.isNotEmpty ? formatted : label,
      locality: json['locality'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      mainText: (json['main_text'] as String? ?? '').trim(),
      secondaryText: (json['secondary_text'] as String? ?? '').trim(),
    );
  }
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? double.nan;
  return double.nan;
}

bool isValidSalonCoordinates(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return false;
  if (!latitude.isFinite || !longitude.isFinite) return false;
  return latitude != 0 || longitude != 0;
}
