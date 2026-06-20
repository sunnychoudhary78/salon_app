import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_constants.dart';
import 'package:saloon_booking/features/onboarding/presentation/widgets/ken_burns_background.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.slide,
    required this.isActive,
    required this.pageIndex,
  });

  final OnboardingSlideData slide;
  final bool isActive;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final horizontalPadding = screenWidth * 0.1;
    final gradientHeight = MediaQuery.sizeOf(context).height * 0.48;

    final headlineStyle = (isCompact
            ? theme.textTheme.displaySmall
            : theme.textTheme.displayMedium)
        ?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.05,
      letterSpacing: -0.5,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: KenBurnsBackground(
            imagePath: slide.image,
            isActive: isActive,
            alignment: slide.imageAlignment,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: gradientHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: horizontalPadding.clamp(24, 56),
          right: horizontalPadding.clamp(24, 56),
          bottom: 160,
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedText(
                      key: ValueKey('heading-$pageIndex-$isActive'),
                      isActive: isActive,
                      delay: Duration.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.headingPrimary,
                            style: headlineStyle?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            slide.headingAccent,
                            style: headlineStyle?.copyWith(
                              color: OnboardingConstants.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AnimatedText(
                      key: ValueKey('divider-$pageIndex-$isActive'),
                      isActive: isActive,
                      delay: const Duration(milliseconds: 120),
                      child: Container(
                        width: 56,
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              OnboardingConstants.accentColor,
                              OnboardingConstants.accentColor
                                  .withValues(alpha: 0.35),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AnimatedText(
                      key: ValueKey('subheading-$pageIndex-$isActive'),
                      isActive: isActive,
                      delay: const Duration(milliseconds: 220),
                      child: Text(
                        slide.subheading,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w400,
                          height: 1.65,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedText extends StatelessWidget {
  const _AnimatedText({
    super.key,
    required this.child,
    required this.isActive,
    required this.delay,
  });

  final Widget child;
  final bool isActive;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return Opacity(opacity: 0, child: child);
    }

    return child
        .animate(key: key, delay: delay)
        .fadeIn(
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
