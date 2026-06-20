import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saloon_booking/features/onboarding/presentation/widgets/onboarding_page_indicator.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

class OnboardingBottomBar extends StatelessWidget {
  const OnboardingBottomBar({
    super.key,
    required this.currentIndex,
    required this.pageCount,
    required this.onNext,
    required this.onGetStarted,
    required this.isLoading,
  });

  final int currentIndex;
  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;
  final bool isLoading;

  bool get _isLastPage => currentIndex == pageCount - 1;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth * 0.1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding.clamp(20, 48),
          0,
          horizontalPadding.clamp(20, 48),
          16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingPageIndicator(
                count: pageCount,
                currentIndex: currentIndex,
              ),
              const SizedBox(height: 24),
              if (_isLastPage)
                PremiumButton(
                  label: 'Get Started',
                  variant: PremiumButtonVariant.accent,
                  loading: isLoading,
                  onPressed: isLoading ? null : onGetStarted,
                  icon: Icons.arrow_forward_rounded,
                ).animate().fadeIn(duration: 400.ms).slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: PremiumButton(
                    label: 'Next',
                    variant: PremiumButtonVariant.accent,
                    expand: false,
                    onPressed: onNext,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ).animate().fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
