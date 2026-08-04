import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';

void main() {
  group('salon_service_names', () {
    test('includes the fixed 15 service names', () {
      expect(kSalonServiceNames, hasLength(15));
      expect(
        kSalonServiceNames,
        containsAll(['Haircut', 'Beard Trim', 'Groom Package']),
      );
      expect(kSalonServiceNames, isNot(contains(kCustomSalonServiceName)));
    });

    test('matches known names case-insensitively', () {
      expect(matchingSalonServiceName('haircut'), 'Haircut');
      expect(isKnownSalonServiceName('BEARD TRIM'), isTrue);
    });

    test('treats unknown names as custom', () {
      expect(matchingSalonServiceName('Bridal Makeup'), isNull);
      expect(isKnownSalonServiceName('Custom Keratin'), isFalse);
    });
  });
}
