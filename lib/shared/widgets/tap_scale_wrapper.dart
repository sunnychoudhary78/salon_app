import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';

/// Subtle scale feedback on press (0.97).
class TapScaleWrapper extends StatefulWidget {
  const TapScaleWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final BorderRadius? borderRadius;

  @override
  State<TapScaleWrapper> createState() => _TapScaleWrapperState();
}

class _TapScaleWrapperState extends State<TapScaleWrapper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.onTap == null) return widget.child;

    final scale = animationsDisabled(context) ? 1.0 : (_pressed ? 0.97 : 1.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: scale,
        duration: kMicroDuration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
