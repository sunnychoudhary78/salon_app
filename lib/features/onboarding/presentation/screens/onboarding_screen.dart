import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_constants.dart';
import 'package:saloon_booking/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:saloon_booking/features/onboarding/presentation/widgets/onboarding_bottom_bar.dart';
import 'package:saloon_booking/features/onboarding/presentation/widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;
  bool _completing = false;

  static const _slides = OnboardingConstants.slides;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      await ref.read(onboardingCompletedProvider.notifier).complete();
      if (mounted) {
        context.go(RoutePaths.login);
      }
    } finally {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                slide: _slides[index],
                isActive: index == _currentIndex,
                pageIndex: index,
              );
            },
          ),
          if (!isLastPage)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 12),
                  child: TextButton(
                    onPressed: _completing ? null : _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OnboardingBottomBar(
              currentIndex: _currentIndex,
              pageCount: _slides.length,
              onNext: _next,
              onGetStarted: _completeOnboarding,
              isLoading: _completing,
            ),
          ),
        ],
      ),
    );
  }
}
