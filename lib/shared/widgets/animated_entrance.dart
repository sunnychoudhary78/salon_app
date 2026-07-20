import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';

class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.index = 0,
    this.style = EntranceStyle.fadeUp,
    this.animateKey,
  });

  final Widget child;
  final Duration delay;
  final int index;
  final EntranceStyle style;
  final Key? animateKey;

  @override
  Widget build(BuildContext context) {
    return child.appEntrance(
      context: context,
      style: style,
      index: index,
      delay: delay,
      animateKey: animateKey,
    );
  }
}
