import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        ),
        // Ambient rose-gold glow — top right
        Positioned(
          top: -80,
          right: -60,
          child: _GlowOrb(
            size: 280,
            color: AppColors.glowAccent.withValues(alpha: 0.12),
          ),
        ),
        // Ambient accent glow — bottom left
        Positioned(
          bottom: 120,
          left: -100,
          child: _GlowOrb(
            size: 320,
            color: AppColors.glowAccent.withValues(alpha: 0.1),
          ),
        ),
        // Subtle warm accent — mid screen
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.35,
          right: -40,
          child: _GlowOrb(
            size: 180,
            color: AppColors.accentDark.withValues(alpha: 0.08),
          ),
        ),
        // Fine grain texture overlay
        const Positioned.fill(child: _NoiseOverlay()),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _NoisePainter(),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.015);
    const step = 4.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        if ((x.toInt() + y.toInt()) % 3 == 0) {
          canvas.drawCircle(Offset(x, y), 0.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
