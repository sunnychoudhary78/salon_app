import 'package:flutter/material.dart';

class OnboardingConstants {
  OnboardingConstants._();

  static const onboardingCompletedKey = 'onboarding_completed';

  static const slides = [
    OnboardingSlideData(
      image: 'assets/splash/splash_1.png',
      headingPrimary: 'Beauty',
      headingAccent: 'Redefined',
      subheading: 'For him. For her. One elevated experience.',
      imageAlignment: Alignment(0, -0.15),
    ),
    OnboardingSlideData(
      image: 'assets/splash/splash_2.png',
      headingPrimary: 'Step Into',
      headingAccent: 'Luxury',
      subheading:
          'Handpicked premium salons, crafted for those who expect more.',
      imageAlignment: Alignment.center,
    ),
    OnboardingSlideData(
      image: 'assets/splash/splash_3.png',
      headingPrimary: 'Crafted',
      headingAccent: 'To Perfection',
      subheading: 'Book elite professionals — and leave transformed.',
      imageAlignment: Alignment(0, -0.1),
    ),
  ];
}

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.image,
    required this.headingPrimary,
    required this.headingAccent,
    required this.subheading,
    required this.imageAlignment,
  });

  final String image;
  final String headingPrimary;
  final String headingAccent;
  final String subheading;
  final Alignment imageAlignment;
}
