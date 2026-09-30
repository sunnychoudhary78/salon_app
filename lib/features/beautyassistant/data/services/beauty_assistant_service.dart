import 'dart:async';

import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/features/beautyassistant/data/models/beauty_chat_models.dart';

/// Replace this local implementation with a Dio call when the endpoint ships.
class BeautyAssistantService {
  BeautyAssistantService({
    this.responseDelay = const Duration(milliseconds: 900),
  });

  final Duration responseDelay;

  Future<BeautyAssistantResponse> sendMessage(String input) async {
    await Future<void>.delayed(responseDelay);
    final query = input.toLowerCase();

    if (_containsAny(query, ['wedding', 'bridal', 'marriage'])) {
      return _response(
        'For a wedding look, it helps to plan ahead. You could consider a facial, hair styling, and makeup based on the look you have in mind.',
        [
          _recommendation('Facial', 'A gentle refresh before the big day.'),
          _recommendation(
            'Hair Styling',
            'Explore styles that work with your outfit.',
          ),
          _recommendation(
            'Bridal Makeup',
            'Find a makeup look for your celebration.',
          ),
        ],
      );
    }
    if (_containsAny(query, ['party', 'event', 'night out'])) {
      return _response(
        'For a party, a polished hairstyle and makeup can bring your look together. Choose a style that feels comfortable and like you.',
        [
          _recommendation('Party Makeup', 'A look tailored to your event.'),
          _recommendation(
            'Hair Styling',
            'Finish your look with a style you love.',
          ),
        ],
      );
    }
    if (_containsAny(query, ['makeup', 'make up'])) {
      return _response(
        'A makeup look can be tailored to the occasion and the finish you prefer, from natural to more defined. What kind of event are you getting ready for?',
        [
          _recommendation(
            'Party Makeup',
            'Browse makeup services for your occasion.',
          ),
        ],
      );
    }
    if (_containsAny(query, ['hair fall', 'hair loss', 'thinning'])) {
      return _response(
        'I can suggest salon grooming services, but hair fall can have many causes. A salon scalp treatment may support your hair care routine; for ongoing or sudden hair loss, please speak with a healthcare professional.',
        [
          _recommendation(
            'Scalp Treatment',
            'A salon service focused on scalp care.',
          ),
          _recommendation(
            'Hair Fall Treatment',
            'Ask a salon about its available hair care options.',
          ),
        ],
      );
    }
    if (_containsAny(query, ['beard', 'tidy', 'trim'])) {
      return _response(
        'For a neat, well-shaped look, you could book a beard trim or beard styling. A stylist can help choose a shape that suits your preference.',
        [
          _recommendation(
            'Beard Trim',
            'A clean up for your preferred beard length.',
          ),
          _recommendation(
            'Beard Styling',
            'Shape and finish your beard your way.',
          ),
        ],
      );
    }
    if (_containsAny(query, ['groom', 'shave'])) {
      return _response(
        'A simple grooming refresh could include a haircut, beard tidy, or a relaxing facial. Pick the services that fit your routine.',
        [
          _recommendation('Haircut', 'A fresh cut to suit your style.'),
          _recommendation('Beard Trim', 'Keep your beard neat and shaped.'),
          _recommendation('Facial', 'Add a relaxing skin care step.'),
        ],
      );
    }
    if (_containsAny(query, ['facial', 'skin', 'glow'])) {
      return _response(
        'For a refreshed look, a facial or cleanup can be a relaxing salon option. Let the salon know about any sensitivities before choosing a service.',
        [
          _recommendation(
            'Facial',
            'Choose a facial that suits your preferences.',
          ),
          _recommendation('Cleanup', 'A shorter skin care refresh.'),
        ],
      );
    }
    if (_containsAny(query, ['hair', 'hairstyle', 'style'])) {
      return _response(
        'There are lots of ways to refresh your hair, from a trim to styling or a hair spa. What look or occasion are you thinking about?',
        [
          _recommendation(
            'Hair Styling',
            'Explore a style for your next occasion.',
          ),
          _recommendation('Hair Spa', 'A relaxing salon hair care service.'),
          _recommendation('Haircut', 'Refresh your shape and length.'),
        ],
      );
    }

    return _response(
      'I can help with beauty, hairstyle, and grooming ideas. Tell me about an occasion or a service you have in mind, such as a wedding look, party makeup, hair care, or beard tidy.',
      const [],
    );
  }

  BeautyAssistantResponse _response(
    String message,
    List<BeautyRecommendation> recommendations,
  ) => BeautyAssistantResponse(
    message: message,
    recommendations: recommendations,
  );

  BeautyRecommendation _recommendation(String serviceName, String description) {
    final catalogName = matchingSalonServiceName(serviceName) ?? serviceName;
    return BeautyRecommendation(
      serviceName: catalogName,
      description: description,
      cta: const RecommendationCta(type: RecommendationCtaType.browseSalons),
    );
  }

  bool _containsAny(String text, List<String> terms) =>
      terms.any(text.contains);
}
