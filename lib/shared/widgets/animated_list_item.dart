import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';

/// Staggered list item wrapper for [ListView.builder] and mapped lists.
class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.style = EntranceStyle.fadeUp,
    this.delay = Duration.zero,
  });

  final int index;
  final Widget child;
  final EntranceStyle style;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedEntrance(
      index: index,
      delay: delay,
      style: style,
      child: child,
    );
  }
}
