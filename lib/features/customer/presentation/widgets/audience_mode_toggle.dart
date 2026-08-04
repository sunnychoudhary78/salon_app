import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/providers/audience_mode_provider.dart';

/// Compact Men/Women capsule for the home greeting row.
class AudienceModeToggle extends ConsumerStatefulWidget {
  const AudienceModeToggle({super.key});

  @override
  ConsumerState<AudienceModeToggle> createState() => _AudienceModeToggleState();
}

class _AudienceModeToggleState extends ConsumerState<AudienceModeToggle> {
  static const _menAsset = 'assets/icon/audience_men.png';
  static const _womenAsset = 'assets/icon/audience_women.png';
  static const double _width = 148;
  static const double _height = 36;

  bool _settingMode = false;

  Future<void> _setMode(AudienceMode mode) async {
    if (_settingMode) return;
    if (ref.read(audienceModeValueProvider) == mode) return;
    _settingMode = true;
    HapticFeedback.selectionClick();
    try {
      await ref.read(audienceModeProvider.notifier).setMode(mode);
    } finally {
      if (mounted) {
        _settingMode = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final mode = ref.watch(audienceModeValueProvider);
    final isMen = mode == AudienceMode.men;

    return Semantics(
      label: isMen ? 'Men mode selected' : 'Women mode selected',
      child: Container(
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.glassBorder.withValues(alpha: 0.65)),
          boxShadow: [
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: kPageDuration,
              curve: Curves.easeOutCubic,
              alignment: isMen ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: (_width - 6) / 2,
                decoration: BoxDecoration(
                  gradient: colors.accentGradient,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _Segment(
                    label: 'Men',
                    asset: _menAsset,
                    selected: isMen,
                    onTap: () => _setMode(AudienceMode.men),
                  ),
                ),
                Expanded(
                  child: _Segment(
                    label: 'Women',
                    asset: _womenAsset,
                    selected: !isMen,
                    onTap: () => _setMode(AudienceMode.women),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  int _pulseGeneration = 0;

  @override
  void didUpdateWidget(covariant _Segment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && widget.selected) {
      _pulseGeneration++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: widget.selected ? 1.06 : 1,
          duration: kMicroDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: widget.selected ? 1 : 0.65,
            duration: kMicroDuration,
            child: ClipOval(
              child: Image.asset(
                widget.asset,
                width: 20,
                height: 20,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: AnimatedDefaultTextStyle(
            duration: kMicroDuration,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              color: widget.selected ? colors.onAccent : colors.textSecondary,
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );

    if (!animationsDisabled(context) && widget.selected) {
      content = content
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
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(17),
        splashColor: colors.accent.withValues(alpha: 0.12),
        highlightColor: colors.accent.withValues(alpha: 0.06),
        child: SizedBox.expand(child: Center(child: content)),
      ),
    );
  }
}
