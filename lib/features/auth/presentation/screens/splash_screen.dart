import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/shared/widgets/app_logo.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (prev, next) {
      if (next.isLoading) return;
    });

    final colors = context.appColors;
    final logoWidth = MediaQuery.sizeOf(context).width * 0.65;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(gradient: colors.authGradient),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppLogo(
                      size: 140,
                      maxWidth: logoWidth.clamp(200.0, 280.0),
                      showGlow: false,
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(),
                const SizedBox(height: 48),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.accent,
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
