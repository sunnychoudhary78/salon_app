import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class PremiumFilterChip extends StatefulWidget {
  const PremiumFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<PremiumFilterChip> createState() => _PremiumFilterChipState();
}

class _PremiumFilterChipState extends State<PremiumFilterChip> {
  int _pulseGeneration = 0;

  @override
  void didUpdateWidget(PremiumFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _pulseGeneration++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget chip = AnimatedContainer(
      duration: kMicroDuration,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: widget.selected ? colors.primarySoft : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.selected ? colors.primary : colors.glassBorder,
          width: widget.selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.selected) ...[
            Icon(Icons.check_rounded, size: 16, color: colors.primary),
            const SizedBox(width: 6),
          ],
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: widget.selected ? colors.primary : colors.textSecondary,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (!animationsDisabled(context)) {
      chip = chip
          .animate(key: ValueKey(_pulseGeneration))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.04, 1.04),
            duration: kMicroDuration,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            begin: const Offset(1.04, 1.04),
            end: const Offset(1, 1),
            duration: kMicroDuration,
            curve: Curves.easeIn,
          );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: chip,
      ),
    );
  }
}
