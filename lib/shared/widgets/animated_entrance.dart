import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.index = 0,
  });

  final Widget child;
  final Duration delay;
  final int index;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay + Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: 300.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }
}
