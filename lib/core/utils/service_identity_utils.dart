import 'package:saloon_booking/core/constants/salon_service_names.dart';

String normalizedServiceIdentityName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

String displayServiceIdentityName(String value) {
  final display = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return display.isEmpty ? 'This service' : display;
}

/// 409 copy matching the owner API: unisex XOR men/women, men+women allowed.
String? serviceIdentityConflictMessage({
  required String serviceName,
  required SalonType requested,
  required Iterable<SalonType> existingServiceFors,
}) {
  final existing = existingServiceFors.toSet();
  final name = displayServiceIdentityName(serviceName);

  if (existing.contains(requested)) {
    return '$name is already added for ${requested.serviceAudienceLabel}';
  }

  final hasUnisex = existing.contains(SalonType.unisex);
  final hasMen = existing.contains(SalonType.men);
  final hasWomen = existing.contains(SalonType.women);

  if (requested == SalonType.unisex && (hasMen || hasWomen)) {
    if (hasMen && hasWomen) {
      return '$name is already added for Men and Women. You cannot also add it as a unisex service.';
    }
    if (hasMen) {
      return '$name is already added for Men. You can add it for Women, but not as a unisex service.';
    }
    return '$name is already added for Women. You can add it for Men, but not as a unisex service.';
  }

  if ((requested == SalonType.men || requested == SalonType.women) &&
      hasUnisex) {
    return '$name is already added for Everyone. Edit that service, or remove it before adding separate Men and Women versions.';
  }

  return null;
}

bool isServiceForAllowedWithSiblings({
  required SalonType requested,
  required Iterable<SalonType> existingServiceFors,
}) {
  return serviceIdentityConflictMessage(
        serviceName: 'Service',
        requested: requested,
        existingServiceFors: existingServiceFors,
      ) ==
      null;
}
