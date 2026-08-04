import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Central animation timings for the app.
const Duration kEntranceDuration = Duration(milliseconds: 320);
const Duration kStaggerStep = Duration(milliseconds: 45);
const Duration kMicroDuration = Duration(milliseconds: 180);
const Duration kPageDuration = Duration(milliseconds: 380);

/// Max list index used for stagger delay (avoids long cascades).
const int kMaxStaggerIndex = 8;

enum EntranceStyle { fadeUp, fadeIn, slideRight, scaleIn }

/// Whether platform / user prefers reduced motion.
bool animationsDisabled(BuildContext context) {
  return MediaQuery.disableAnimationsOf(context);
}

/// Caps stagger index for performance on long lists.
int cappedStaggerIndex(int index) =>
    index > kMaxStaggerIndex ? kMaxStaggerIndex : index;

Duration staggerDelay(int index, {Duration extra = Duration.zero}) {
  return extra + kStaggerStep * cappedStaggerIndex(index);
}

extension AppEntranceExtension on Widget {
  /// Applies a preset entrance animation via [flutter_animate].
  Widget appEntrance({
    required BuildContext context,
    EntranceStyle style = EntranceStyle.fadeUp,
    int index = 0,
    Duration delay = Duration.zero,
    Key? animateKey,
  }) {
    if (animationsDisabled(context)) return this;

    final totalDelay = staggerDelay(index, extra: delay);
    final duration = kEntranceDuration;

    final chain = animateKey != null
        ? animate(key: animateKey, delay: totalDelay)
        : animate(delay: totalDelay);

    switch (style) {
      case EntranceStyle.fadeUp:
        return chain
            .fadeIn(duration: duration, curve: Curves.easeOutCubic)
            .slideY(
              begin: 0.06,
              end: 0,
              duration: duration,
              curve: Curves.easeOutCubic,
            )
            .scale(
              begin: const Offset(0.98, 0.98),
              end: const Offset(1, 1),
              duration: duration,
              curve: Curves.easeOutCubic,
            );
      case EntranceStyle.fadeIn:
        return chain.fadeIn(duration: duration, curve: Curves.easeOutCubic);
      case EntranceStyle.slideRight:
        return chain
            .fadeIn(duration: duration, curve: Curves.easeOutCubic)
            .slideX(
              begin: 0.08,
              end: 0,
              duration: duration,
              curve: Curves.easeOutCubic,
            );
      case EntranceStyle.scaleIn:
        return chain
            .fadeIn(duration: duration, curve: Curves.easeOutCubic)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: duration,
              curve: Curves.easeOutCubic,
            );
    }
  }

  /// Subtle continuous float for empty-state icons.
  Widget appFloatLoop({required BuildContext context}) {
    if (animationsDisabled(context)) return this;
    return animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).slideY(begin: 0, end: -0.02, duration: 2000.ms, curve: Curves.easeInOut);
  }
}

/// Scale-in + fade for dialog surfaces.
Widget animateDialogSurface(BuildContext context, Widget child) {
  if (animationsDisabled(context)) return child;
  return child
      .animate()
      .fadeIn(duration: kEntranceDuration, curve: Curves.easeOutCubic)
      .scale(
        begin: const Offset(0.94, 0.94),
        end: const Offset(1, 1),
        duration: kEntranceDuration,
        curve: Curves.easeOutBack,
      );
}
