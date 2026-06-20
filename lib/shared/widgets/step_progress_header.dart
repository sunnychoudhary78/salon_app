import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class StepProgressHeader extends StatelessWidget {
  const StepProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.titles,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${currentStep + 1} of $totalSteps',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          titles[currentStep],
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        SmoothPageIndicator(
          controller: PageController(initialPage: currentStep),
          count: totalSteps,
          effect: const ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            expansionFactor: 3,
            activeDotColor: AppColors.accent,
            dotColor: AppColors.glassBorder,
          ),
          onDotClicked: (_) {},
        ),
      ],
    );
  }
}
