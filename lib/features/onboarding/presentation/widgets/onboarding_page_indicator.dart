import 'package:flutter/material.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_constants.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          margin: EdgeInsets.only(right: index < count - 1 ? 8 : 0),
          width: isActive ? 28 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? OnboardingConstants.accentColor
                : Colors.white.withValues(alpha: 0.28),
          ),
        );
      }),
    );
  }
}
