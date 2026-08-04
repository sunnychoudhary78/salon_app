import 'package:saloon_booking/core/constants/salon_service_names.dart';

const String _kMenServiceIconsBase = 'assets/services/men';
const String _kWomenServiceIconsBase = 'assets/services/women';

const Map<String, String> _kSlugByName = {
  'Haircut': 'haircut',
  'Hair Color': 'hair-color',
  'Hair Wash': 'hair-wash',
  'Hair Styling': 'hair-styling',
  'Hair Spa': 'hair-spa',
  'Hair Highlights': 'hair-highlights',
  'Hair Smoothening': 'hair-smoothening',
  'Hair Straightening': 'hair-straightening',
  'Hair Fall Treatment': 'hair-fall-treatment',
  'Keratin Treatment': 'keratin-treatment',
  'Scalp Treatment': 'scalp-treatment',
  'Dandruff Treatment': 'dandruff-treatment',
  'Facial': 'facial',
  'Cleanup': 'cleanup',
  'Hydra Facial': 'hydra-facial',
  'Face Scrub': 'face-scrub',
  'Face Massage': 'face-massage',
  'De-Tan Treatment': 'de-tan-treatment',
  'Eyebrow Grooming': 'eyebrow-grooming',
  'Threading': 'threading',
  'Waxing': 'waxing',
  'Head Massage': 'head-massage',
  'Body Massage': 'body-massage',
  'Foot Spa': 'foot-spa',
  'Manicure': 'manicure',
  'Pedicure': 'pedicure',
  'Beard Trim': 'beard-trim',
  'Beard Color': 'beard-color',
  'Beard Styling': 'beard-styling',
  'Shaving': 'shaving',
  'Groom Package': 'groom-package',
  'Groom Makeup': 'groom-makeup',
  'Signature Grooming Package': 'signature-grooming-package',
  'Bridal Makeup': 'bridal-makeup',
  'Bridal Beauty Package': 'bridal-beauty-package',
  'Pre Bridal Package': 'pre-bridal-package',
  'Party Makeup': 'party-makeup',
  'Nail Art': 'nail-art',
  'Nail Extensions': 'nail-extensions',
  'Hair Extensions': 'hair-extensions',
  'Hair Botox': 'hair-botox',
};

/// Asset path for a known salon service icon for [audience], or null for custom/unknown names.
String? salonServiceIconAsset(
  String? serviceName, {
  AudienceMode audience = AudienceMode.men,
}) {
  final known = matchingSalonServiceName(serviceName);
  if (known == null) return null;

  final slug = _kSlugByName[known];
  if (slug == null) return null;

  // Gender-unique services only exist in one folder.
  if (isMenOnlyServiceName(known)) {
    return '$_kMenServiceIconsBase/$slug.png';
  }
  if (isWomenOnlyServiceName(known)) {
    return '$_kWomenServiceIconsBase/$slug.png';
  }

  final base = audience == AudienceMode.women
      ? _kWomenServiceIconsBase
      : _kMenServiceIconsBase;
  return '$base/$slug.png';
}
