import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/image_decode_utils.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:saloon_booking/core/utils/platform_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_helpers.dart';
import 'package:saloon_booking/shared/widgets/salon_cube_image_slider.dart';

class SalonHeroSection extends StatefulWidget {
  const SalonHeroSection({
    super.key,
    required this.salon,
    required this.onBack,
  });

  final SalonModel salon;
  final VoidCallback onBack;

  static const double heroHeight = 250;

  @override
  State<SalonHeroSection> createState() => _SalonHeroSectionState();
}

class _SalonHeroSectionState extends State<SalonHeroSection> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;
    final colors = context.appColors;
    final rawImages = salon.carouselImages.isNotEmpty
        ? salon.carouselImages
        : salon.allDisplayImages;
    final images = _dedupeImages(rawImages);
    final isOpen = salonIsOpenNow(salon);
    final verified = salonIsVerified(salon);
    final borderRadius = const BorderRadius.only(
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    );

    final ratingLabel = salon.reviewCount > 0 && salon.averageRating != null
        ? salon.averageRating!.toStringAsFixed(1)
        : 'NEW';
    final distanceLabel = salon.distanceKm != null
        ? formatDistanceKm(salon.distanceKm)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: SalonHeroSection.heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: borderRadius,
                child: images.isEmpty
                    ? _placeholder(context)
                    : images.length == 1
                    ? CachedNetworkImage(
                        imageUrl: resolveImageUrl(images.first),
                        fit: BoxFit.cover,
                        memCacheWidth: memCachePx(
                          context,
                          MediaQuery.sizeOf(context).width,
                        ),
                        memCacheHeight: memCachePx(
                          context,
                          SalonHeroSection.heroHeight,
                        ),
                        errorWidget: (context, error, stackTrace) =>
                            _placeholder(context),
                      )
                    : SalonCubeImageSlider(
                        images: images,
                        height: SalonHeroSection.heroHeight,
                        borderRadius: BorderRadius.zero,
                        sliderKey: salon.id,
                        showDotIndicator: false,
                        onPageChanged: (index) {
                          if (!mounted) return;
                          setState(() => _pageIndex = index);
                        },
                      ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (i) {
                      final active = i == _pageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: _HeroIconButton(
                      icon: platformBackIcon(context),
                      onTap: widget.onBack,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            salon.salonName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (verified)
                Expanded(
                  child: _MetaBadge(
                    icon: Icons.verified_rounded,
                    label: 'Verified',
                    color: context.appColors.accent,
                  ),
                ),
              if (verified) const SizedBox(width: 8),
              Expanded(
                child: _MetaBadge(
                  icon: Icons.star_rounded,
                  label: ratingLabel,
                  color: AppColors.starGold,
                ),
              ),
              if (distanceLabel != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _MetaBadge(
                    icon: Icons.near_me_rounded,
                    label: distanceLabel,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _MetaBadge(
                  icon: Icons.circle,
                  iconSize: 8,
                  label: isOpen ? 'Open' : 'Closed',
                  color: isOpen ? AppColors.success : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.appColors.glassFill,
      child: Center(
        child: Icon(
          Icons.store_rounded,
          size: 56,
          color: context.appColors.textMuted,
        ),
      ),
    );
  }

  static List<String> _dedupeImages(List<String> images) {
    final seen = <String>{};
    return [
      for (final image in images)
        if (image.isNotEmpty && seen.add(image)) image,
    ];
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 14,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
