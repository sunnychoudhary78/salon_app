import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/shared/widgets/app_logo.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.headline,
    this.subtitle,
    this.showLogo = false,
    this.logoSize = 72,
    this.logoHero = false,
    this.onBack,
    required this.child,
  });

  /// Shared hero logo size for login / profile auth screens.
  static const double heroLogoSize = 220;

  final String headline;
  final String? subtitle;
  final bool showLogo;
  final double logoSize;
  final bool logoHero;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    final heroLogoWidth = (screenWidth * 0.82).clamp(260.0, 340.0);
    final effectiveLogoSize = logoHero ? logoSize.clamp(140.0, 240.0) : logoSize;
    final keyboardLogoSize =
        keyboardOpen ? (effectiveLogoSize * 0.82).clamp(100.0, 180.0) : effectiveLogoSize;
    final headerFlex = logoHero ? 3 : 2;
    final sheetFlex = logoHero ? 2 : 3;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.authGradient),
          ),
          Positioned(
            top: logoHero ? 40 : -60,
            left: 0,
            right: 0,
            child: Center(
              child: _GlowOrb(
                size: logoHero ? 320 : 220,
                color: AppColors.glowAccent.withValues(alpha: logoHero ? 0.28 : 0.2),
              ),
            ),
          ),
          Positioned(
            bottom: logoHero ? 280 : 200,
            left: -80,
            child: _GlowOrb(
              size: 200,
              color: AppColors.accentDark.withValues(alpha: 0.12),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: headerFlex,
                  child: Padding(
                    padding:
                        EdgeInsets.fromLTRB(24, logoHero ? 16 : 8, 24, 0),
                    child: logoHero && showLogo
                        ? _HeroHeader(
                            onBack: onBack,
                            logoSize: keyboardLogoSize,
                            logoWidth: heroLogoWidth,
                            headline: keyboardOpen ? '' : headline,
                            subtitle: keyboardOpen ? null : subtitle,
                            compact: keyboardOpen,
                          )
                        : _StandardHeader(
                            onBack: onBack,
                            showLogo: showLogo,
                            logoSize: keyboardOpen
                                ? logoSize.clamp(56.0, 72.0)
                                : logoSize,
                            headline: headline,
                            subtitle: keyboardOpen ? null : subtitle,
                            compact: keyboardOpen,
                          ),
                  ),
                ),
                Expanded(
                  flex: sheetFlex,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.authSheet,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.15),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 32,
                          offset: const Offset(0, -12),
                        ),
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          28,
                          keyboardOpen ? 20 : 32,
                          28,
                          keyboardOpen ? 24 : 32,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.logoSize,
    required this.logoWidth,
    required this.headline,
    this.subtitle,
    this.onBack,
    this.compact = false,
  });

  final double logoSize;
  final double logoWidth;
  final String headline;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          )
        else
          SizedBox(height: compact ? 4 : 8),
        if (!compact) const Spacer(),
        AppLogo(
          size: logoSize,
          maxWidth: logoWidth,
          showGlow: true,
        ),
        if (headline.isNotEmpty) ...[
          SizedBox(height: compact ? 10 : 20),
          Text(
            headline,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          SizedBox(height: compact ? 4 : 6),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
        if (!compact) const Spacer(),
      ],
    );
  }
}

class _StandardHeader extends StatelessWidget {
  const _StandardHeader({
    required this.showLogo,
    required this.logoSize,
    required this.headline,
    this.subtitle,
    this.onBack,
    this.compact = false,
  });

  final bool showLogo;
  final double logoSize;
  final String headline;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          )
        else
          SizedBox(height: compact ? 8 : 48),
        if (!compact) const Spacer(),
        if (showLogo) ...[
          AppLogo(size: logoSize),
          SizedBox(height: compact ? 12 : 20),
        ],
        if (headline.isNotEmpty)
          Text(
            headline,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 22 : null,
                ),
          ),
        if (subtitle != null) ...[
          SizedBox(height: compact ? 4 : 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.75),
                ),
          ),
        ],
        SizedBox(height: compact ? 8 : 24),
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
