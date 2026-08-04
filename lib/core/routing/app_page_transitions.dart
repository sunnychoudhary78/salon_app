import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';

/// Fade + subtle horizontal slide for standard push routes.
CustomTransitionPage<T> fadeSlidePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: kPageDuration,
    reverseTransitionDuration: kPageDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (animationsDisabled(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Slide up for full-screen form flows.
CustomTransitionPage<T> modalUpPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: kPageDuration,
    reverseTransitionDuration: kPageDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (animationsDisabled(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Helper for GoRoute pageBuilder with fade-slide transition.
GoRouterPageBuilder fadeSlideBuilder(
  Widget Function(BuildContext, GoRouterState) builder,
) {
  return (context, state) =>
      fadeSlidePage<void>(key: state.pageKey, child: builder(context, state));
}

GoRouterPageBuilder modalUpBuilder(
  Widget Function(BuildContext, GoRouterState) builder,
) {
  return (context, state) =>
      modalUpPage<void>(key: state.pageKey, child: builder(context, state));
}
