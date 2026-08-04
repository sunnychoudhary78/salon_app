/// Shared services available for men and women (same name, gender-specific icons).
const List<String> kSharedSalonServiceNames = [
  'Haircut',
  'Hair Color',
  'Hair Wash',
  'Hair Styling',
  'Hair Spa',
  'Hair Highlights',
  'Hair Smoothening',
  'Hair Straightening',
  'Hair Fall Treatment',
  'Keratin Treatment',
  'Scalp Treatment',
  'Dandruff Treatment',
  'Facial',
  'Cleanup',
  'Hydra Facial',
  'Face Scrub',
  'Face Massage',
  'De-Tan Treatment',
  'Eyebrow Grooming',
  'Threading',
  'Waxing',
  'Head Massage',
  'Body Massage',
  'Foot Spa',
  'Manicure',
  'Pedicure',
];

/// Men-only catalog names.
const List<String> kMenOnlySalonServiceNames = [
  'Beard Trim',
  'Beard Color',
  'Beard Styling',
  'Shaving',
  'Groom Package',
  'Groom Makeup',
  'Signature Grooming Package',
];

/// Women-only catalog names.
const List<String> kWomenOnlySalonServiceNames = [
  'Bridal Makeup',
  'Bridal Beauty Package',
  'Pre Bridal Package',
  'Party Makeup',
  'Nail Art',
  'Nail Extensions',
  'Hair Extensions',
  'Hair Botox',
];

/// Full combined catalog (unisex picker).
const List<String> kSalonServiceNames = [
  ...kSharedSalonServiceNames,
  ...kMenOnlySalonServiceNames,
  ...kWomenOnlySalonServiceNames,
];

const List<String> kMenSalonServiceNames = [
  ...kSharedSalonServiceNames,
  ...kMenOnlySalonServiceNames,
];

const List<String> kWomenSalonServiceNames = [
  ...kSharedSalonServiceNames,
  ...kWomenOnlySalonServiceNames,
];

/// Sentinel for the owner form when the service is not in the catalog.
const String kCustomSalonServiceName = 'Other / Custom';

/// Salon audience type stored on the salon / application.
enum SalonType {
  men('MEN'),
  women('WOMEN'),
  unisex('UNISEX');

  const SalonType(this.apiValue);
  final String apiValue;

  static SalonType? tryParse(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final type in SalonType.values) {
      if (type.apiValue == normalized) return type;
    }
    return null;
  }

  static SalonType parse(String? value, {SalonType fallback = SalonType.unisex}) {
    return tryParse(value) ?? fallback;
  }
}

/// Customer browse / icon audience mode.
enum AudienceMode {
  men('men'),
  women('women');

  const AudienceMode(this.apiValue);
  final String apiValue;

  static AudienceMode? tryParse(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final mode in AudienceMode.values) {
      if (mode.apiValue == normalized) return mode;
    }
    return null;
  }

  static AudienceMode fromGender(String? gender) {
    final normalized = gender?.trim().toLowerCase();
    if (normalized == 'female') return AudienceMode.women;
    return AudienceMode.men;
  }

  AudienceMode get opposite =>
      this == AudienceMode.men ? AudienceMode.women : AudienceMode.men;
}

List<String> serviceNamesForSalonType(SalonType type) {
  switch (type) {
    case SalonType.men:
      return kMenSalonServiceNames;
    case SalonType.women:
      return kWomenSalonServiceNames;
    case SalonType.unisex:
      return kSalonServiceNames;
  }
}

bool isKnownSalonServiceName(String? name) {
  return matchingSalonServiceName(name) != null;
}

String? matchingSalonServiceName(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  for (final known in kSalonServiceNames) {
    if (known.toLowerCase() == trimmed.toLowerCase()) return known;
  }
  return null;
}

bool isMenOnlyServiceName(String? name) {
  final known = matchingSalonServiceName(name);
  if (known == null) return false;
  return kMenOnlySalonServiceNames.any(
    (n) => n.toLowerCase() == known.toLowerCase(),
  );
}

bool isWomenOnlyServiceName(String? name) {
  final known = matchingSalonServiceName(name);
  if (known == null) return false;
  return kWomenOnlySalonServiceNames.any(
    (n) => n.toLowerCase() == known.toLowerCase(),
  );
}

/// Gender-unique services for the opposite audience are hidden; custom names stay visible.
bool isServiceVisibleForAudience(String? serviceName, AudienceMode audience) {
  final trimmed = serviceName?.trim() ?? '';
  if (trimmed.isEmpty) return false;
  if (matchingSalonServiceName(trimmed) == null) return true;
  if (audience == AudienceMode.women) return !isMenOnlyServiceName(trimmed);
  return !isWomenOnlyServiceName(trimmed);
}

AudienceMode defaultAudienceForSalonType(SalonType type) {
  switch (type) {
    case SalonType.women:
      return AudienceMode.women;
    case SalonType.men:
    case SalonType.unisex:
      return AudienceMode.men;
  }
}
