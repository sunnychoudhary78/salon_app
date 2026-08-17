import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';

void main() {
  group('ServiceModel', () {
    test('parses a category-free service response', () {
      final service = ServiceModel.fromJson({
        'id': 42,
        'service_name': 'Classic cut',
        'description': 'Includes consultation and styling',
        'price': '650.00',
        'duration_minutes': '45',
        'status': 'ACTIVE',
        'service_for': 'MEN',
      });

      expect(service.id, '42');
      expect(service.serviceName, 'Classic cut');
      expect(service.description, 'Includes consultation and styling');
      expect(service.price, 650);
      expect(service.durationMinutes, 45);
      expect(service.serviceFor, SalonType.men);
    });

    test('defaults service_for to UNISEX when missing', () {
      final service = ServiceModel.fromJson({
        'id': '1',
        'service_name': 'Haircut',
        'price': '300',
      });
      expect(service.serviceFor, SalonType.unisex);
    });

    test('creates a payload without category_id', () {
      const service = ServiceModel(
        id: '42',
        serviceName: 'Classic cut',
        price: 650,
        durationMinutes: 45,
        description: 'Includes consultation and styling',
        serviceFor: SalonType.women,
      );

      final payload = service.toCreateJson(
        description: service.description,
        durationMinutes: service.durationMinutes,
        status: 'ACTIVE',
      );

      expect(payload, {
        'service_name': 'Classic cut',
        'price': 650,
        'description': 'Includes consultation and styling',
        'duration_minutes': 45,
        'status': 'ACTIVE',
        'service_for': 'WOMEN',
      });
      expect(payload, isNot(contains('category_id')));
    });

    test('keeps same-name variants distinct by id, description, and price', () {
      final services = [
        ServiceModel.fromJson({
          'id': 'basic',
          'service_name': 'Haircut',
          'description': 'Basic trim',
          'price': '300.00',
          'service_for': 'MEN',
        }),
        ServiceModel.fromJson({
          'id': 'premium',
          'service_name': 'Haircut',
          'description': 'Wash, cut, and styling',
          'price': '650.00',
          'service_for': 'WOMEN',
        }),
      ];

      expect(
        services.map((service) => service.serviceName),
        everyElement('Haircut'),
      );
      expect(services.map((service) => service.id), ['basic', 'premium']);
      expect(services.map((service) => service.description), [
        'Basic trim',
        'Wash, cut, and styling',
      ]);
      expect(services.map((service) => service.price), [300, 650]);
      expect(services.map((service) => service.serviceFor), [
        SalonType.men,
        SalonType.women,
      ]);
    });
  });

  group('isServiceVisibleForAudience', () {
    test('uses service_for when provided', () {
      expect(
        isServiceVisibleForAudience(
          'Haircut',
          AudienceMode.men,
          serviceFor: SalonType.men,
        ),
        isTrue,
      );
      expect(
        isServiceVisibleForAudience(
          'Haircut',
          AudienceMode.men,
          serviceFor: SalonType.women,
        ),
        isFalse,
      );
      expect(
        isServiceVisibleForAudience(
          'Haircut',
          AudienceMode.women,
          serviceFor: SalonType.unisex,
        ),
        isTrue,
      );
    });

    test('falls back to catalog name heuristics without service_for', () {
      expect(
        isServiceVisibleForAudience('Beard Trim', AudienceMode.women),
        isFalse,
      );
      expect(
        isServiceVisibleForAudience('Bridal Makeup', AudienceMode.men),
        isFalse,
      );
      expect(
        isServiceVisibleForAudience('Haircut', AudienceMode.men),
        isTrue,
      );
    });
  });
}
