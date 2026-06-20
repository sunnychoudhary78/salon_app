import 'package:flutter/material.dart';

class OnboardingConstants {
  OnboardingConstants._();

  static const onboardingCompletedKey = 'onboarding_completed';

  /// Premium accent used across onboarding typography.
  static const accentColor = Color(0xFFD4A574);

  static const slides = [
    OnboardingSlideData(
      image: 'assets/splash/splash1.png',
      headingPrimary: 'Confidence',
      headingAccent: 'Starts Here',
      subheading: 'Refined haircuts and grooming crafted for modern men.',
      imageAlignment: Alignment.topCenter,
    ),
    OnboardingSlideData(
      image: 'assets/splash/splash2.png',
      headingPrimary: 'Your',
      headingAccent: 'Time Matters',
      subheading: 'Find and book the perfect appointment in seconds.',
      imageAlignment: Alignment.center,
    ),
    OnboardingSlideData(
      image: 'assets/splash/splash3.png',
      headingPrimary: 'Elevate',
      headingAccent: 'Your Style',
      subheading: 'Premium salons. Skilled barbers. Exceptional results.',
      imageAlignment: Alignment.bottomCenter,
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
