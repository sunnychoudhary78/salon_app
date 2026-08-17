import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/notifications/notification_service.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_constants.dart';
import 'package:saloon_booking/features/onboarding/data/onboarding_repository.dart';
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
      if (!mounted) return;
      await _primeNotificationPermission();
      if (mounted) {
        context.go(RoutePaths.login);
      }
    } finally {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }

  Future<void> _primeNotificationPermission() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (prefs.getBool(notificationPermissionPrimedKey) ?? false) {
      return;
    }

    if (!mounted) return;
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stay updated'),
          content: const Text(
            'CATCHY uses notifications for booking requests, confirmations, '
            'and reminders. Allow notifications so you never miss an update.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    await prefs.setBool(notificationPermissionPrimedKey, true);

    if (shouldRequest == true && mounted) {
      await ref.read(notificationServiceProvider).ensureOsPermission();
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
                      foregroundColor: Colors.white.withValues(alpha: 0.85),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w500,
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
