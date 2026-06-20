class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.label,
    required this.address,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  final String placeId;
  final String label;
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id']?.toString() ?? '',
      label: json['label'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
