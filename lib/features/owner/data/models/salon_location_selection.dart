import 'package:geocoding/geocoding.dart';
import 'package:saloon_booking/core/utils/salon_geocoding.dart';
import 'package:saloon_booking/features/owner/data/models/place_suggestion.dart';

class SalonLocationSelection {
  const SalonLocationSelection({
    required this.street,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.formattedAddress = '',
    this.locality = '',
    this.postalCode = '',
    this.isConfirmed = false,
  });

  /// Street line (maps to API `address`).
  final String street;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String locality;
  final String postalCode;
  final bool isConfirmed;

  /// Backward-compatible alias for [street].
  String get address => street;

  String get displayLabel {
    final formatted = formattedAddress.trim();
    if (formatted.isNotEmpty) return formatted;
    final streetLine = street.trim();
    if (streetLine.isNotEmpty) return streetLine;
    final cityState = cityStateLine;
    if (cityState.isNotEmpty) return cityState;
    return formatCoordinatesLabel(latitude, longitude);
  }

  String get detailLine {
    final parts = <String>[
      if (street.trim().isNotEmpty && street.trim() != formattedAddress.trim())
        street.trim(),
      if (locality.trim().isNotEmpty) locality.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim(),
      if (postalCode.trim().isNotEmpty) postalCode.trim(),
    ];
    // Prefer a compact secondary line without duplicating the primary label.
    final joined = parts.toSet().join(', ');
    if (joined.isNotEmpty && joined != displayLabel) return joined;
    return cityStateLine;
  }

  bool get isComplete {
    final hasAddressLine =
        formattedAddress.trim().isNotEmpty || street.trim().isNotEmpty;
    return hasAddressLine &&
        city.trim().isNotEmpty &&
        state.trim().isNotEmpty &&
        isValidSalonCoordinates(latitude, longitude);
  }

  String get cityStateLine {
    final parts = <String>[
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim(),
      if (postalCode.trim().isNotEmpty) postalCode.trim(),
    ];
    return parts.join(', ');
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'address': street.trim(),
      'street': street.trim(),
      'formatted_address': formattedAddress.trim().isNotEmpty
          ? formattedAddress.trim()
          : displayLabel,
      'locality': locality.trim().isEmpty ? null : locality.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'postal_code': postalCode.trim().isEmpty ? null : postalCode.trim(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  SalonLocationSelection copyWith({
    String? street,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    String? locality,
    String? postalCode,
    bool? isConfirmed,
  }) {
    return SalonLocationSelection(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      locality: locality ?? this.locality,
      postalCode: postalCode ?? this.postalCode,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  SalonLocationSelection confirmed() => copyWith(isConfirmed: true);

  factory SalonLocationSelection.fromPlace(PlaceSuggestion place) {
    final formatted = place.formattedAddress.trim();
    final street = place.street.trim().isNotEmpty
        ? place.street.trim()
        : (formatted.isNotEmpty
              ? formatted.split(',').first.trim()
              : place.label.trim());
    final city = place.city.trim();
    final state = place.state.trim();
    final locality = place.locality.trim();
    final postalCode = place.postalCode.trim();

    return SalonLocationSelection(
      street: street,
      city: city,
      state: state,
      latitude: place.latitude,
      longitude: place.longitude,
      formattedAddress: formatted.isNotEmpty ? formatted : place.label.trim(),
      locality: locality,
      postalCode: postalCode,
    );
  }

  factory SalonLocationSelection.fromPlacemark({
    required Placemark place,
    required double latitude,
    required double longitude,
  }) {
    final street = _streetFromPlacemark(place);
    final locality = (place.subLocality ?? '').trim();
    final city = _cityFromPlacemark(place);
    final state = (place.administrativeArea ?? '').trim();
    final postalCode = (place.postalCode ?? '').trim();
    final formatted = _formattedFromParts(
      street: street,
      locality: locality,
      city: city,
      state: state,
      postalCode: postalCode,
    );

    return SalonLocationSelection(
      street: street.isNotEmpty ? street : (city.isNotEmpty ? city : formatted),
      city: city,
      state: state,
      latitude: latitude,
      longitude: longitude,
      formattedAddress: formatted,
      locality: locality,
      postalCode: postalCode,
    );
  }

  factory SalonLocationSelection.fromSalonFields({
    required String? address,
    required String? city,
    required String? state,
    required double? latitude,
    required double? longitude,
    String? formattedAddress,
    String? locality,
    String? postalCode,
    String? street,
    bool isConfirmed = true,
  }) {
    final streetLine = (street ?? address ?? '').trim();
    final c = (city ?? '').trim();
    final s = (state ?? '').trim();
    final lat = latitude ?? 0;
    final lng = longitude ?? 0;
    final formatted = (formattedAddress ?? '').trim();
    final loc = (locality ?? '').trim();
    final pin = (postalCode ?? '').trim();

    return SalonLocationSelection(
      street: streetLine,
      city: c,
      state: s,
      latitude: lat,
      longitude: lng,
      formattedAddress: formatted.isNotEmpty
          ? formatted
          : _formattedFromParts(
              street: streetLine,
              locality: loc,
              city: c,
              state: s,
              postalCode: pin,
            ),
      locality: loc,
      postalCode: pin,
      isConfirmed: isConfirmed,
    );
  }

  static String _streetFromPlacemark(Placemark place) {
    final parts = <String>[
      if (place.subThoroughfare?.trim().isNotEmpty == true)
        place.subThoroughfare!.trim(),
      if (place.thoroughfare?.trim().isNotEmpty == true)
        place.thoroughfare!.trim(),
      if (place.subLocality?.trim().isNotEmpty == true)
        place.subLocality!.trim(),
      if (place.name?.trim().isNotEmpty == true &&
          place.name!.trim() != place.thoroughfare?.trim())
        place.name!.trim(),
    ];
    final street = parts.where((p) => p.isNotEmpty).toSet().join(', ');
    if (street.isNotEmpty) return street;
    return (place.street ?? place.name ?? '').trim();
  }

  static String _cityFromPlacemark(Placemark place) {
    return (place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            '')
        .trim();
  }

  static String _formattedFromParts({
    required String street,
    required String locality,
    required String city,
    required String state,
    required String postalCode,
  }) {
    final parts = <String>[
      if (street.isNotEmpty) street,
      if (locality.isNotEmpty && locality != street) locality,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
    ];
    return parts.toSet().join(', ');
  }
}
