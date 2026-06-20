enum LocationSource { gps, manualCity }

class SelectedLocation {
  const SelectedLocation({
    required this.displayLabel,
    required this.source,
    this.latitude,
    this.longitude,
    this.city,
  });

  const SelectedLocation.unset()
      : displayLabel = '',
        source = LocationSource.gps,
        latitude = null,
        longitude = null,
        city = null;

  final String displayLabel;
  final LocationSource source;
  final double? latitude;
  final double? longitude;
  final String? city;

  bool get isSet => displayLabel.isNotEmpty;

  SelectedLocation copyWith({
    String? displayLabel,
    LocationSource? source,
    double? latitude,
    double? longitude,
    String? city,
    bool clearCoords = false,
    bool clearCity = false,
  }) {
    return SelectedLocation(
      displayLabel: displayLabel ?? this.displayLabel,
      source: source ?? this.source,
      latitude: clearCoords ? null : (latitude ?? this.latitude),
      longitude: clearCoords ? null : (longitude ?? this.longitude),
      city: clearCity ? null : (city ?? this.city),
    );
  }

  Map<String, dynamic> toJson() => {
        'display_label': displayLabel,
        'source': source.name,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (city != null) 'city': city,
      };

  factory SelectedLocation.fromJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String? ?? LocationSource.gps.name;
    return SelectedLocation(
      displayLabel: json['display_label'] as String? ?? '',
      source: LocationSource.values.firstWhere(
        (s) => s.name == sourceName,
        orElse: () => LocationSource.gps,
      ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'] as String?,
    );
  }
}
