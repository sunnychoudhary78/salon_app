const Map<String, String> ownerProfileFieldLabels = {
  'cover_image': 'Cover photo',
  'description': 'Description',
  'gallery_images': 'Gallery photos',
  'phone': 'Phone number',
  'hours': 'Opening hours',
  'opening_time': 'Opening hours',
  'closing_time': 'Closing hours',
  'active_services': 'Services',
};

String ownerProfileFieldLabel(String field) =>
    ownerProfileFieldLabels[field] ?? field.replaceAll('_', ' ');

List<String> humanizeMissingFields(List<String> missing) {
  return missing.map(ownerProfileFieldLabel).toList();
}

List<String> aggregateMissingFields(
  List<({String salonName, List<String> missing})> salons,
) {
  final unique = <String>{};
  for (final salon in salons) {
    unique.addAll(salon.missing);
  }
  return humanizeMissingFields(unique.toList()..sort());
}
