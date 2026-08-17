import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/utils/service_identity_utils.dart';

void main() {
  group('serviceIdentityConflictMessage', () {
    test('allows Men plus Women', () {
      expect(
        serviceIdentityConflictMessage(
          serviceName: 'Haircut',
          requested: SalonType.women,
          existingServiceFors: const [SalonType.men],
        ),
        isNull,
      );
    });

    test('blocks exact same gender', () {
      expect(
        serviceIdentityConflictMessage(
          serviceName: ' Haircut ',
          requested: SalonType.men,
          existingServiceFors: const [SalonType.men],
        ),
        'Haircut is already added for Men',
      );
    });

    test('blocks Unisex when Men exists', () {
      expect(
        serviceIdentityConflictMessage(
          serviceName: 'Haircut',
          requested: SalonType.unisex,
          existingServiceFors: const [SalonType.men],
        ),
        'Haircut is already added for Men. You can add it for Women, but not as a unisex service.',
      );
    });

    test('blocks Unisex when Men and Women exist', () {
      expect(
        serviceIdentityConflictMessage(
          serviceName: 'Haircut',
          requested: SalonType.unisex,
          existingServiceFors: const [SalonType.men, SalonType.women],
        ),
        'Haircut is already added for Men and Women. You cannot also add it as a unisex service.',
      );
    });

    test('blocks Men when Unisex exists', () {
      expect(
        serviceIdentityConflictMessage(
          serviceName: 'Haircut',
          requested: SalonType.men,
          existingServiceFors: const [SalonType.unisex],
        ),
        'Haircut is already added for Everyone. Edit that service, or remove it before adding separate Men and Women versions.',
      );
    });

    test('ignores the current row by using empty siblings', () {
      expect(
        serviceIdentityConflictMessage(
          serviceName: 'Haircut',
          requested: SalonType.men,
          existingServiceFors: const [],
        ),
        isNull,
      );
    });
  });
}
