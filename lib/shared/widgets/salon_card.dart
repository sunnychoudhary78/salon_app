import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/shared/widgets/glass_overlay_panel.dart';
import 'package:saloon_booking/shared/widgets/salon_card_image_carousel.dart';
import 'package:saloon_booking/shared/widgets/salon_distance_badge.dart';
import 'package:saloon_booking/shared/widgets/salon_promo_chips.dart';
import 'package:saloon_booking/shared/widgets/salon_rating_badge.dart';
import 'package:saloon_booking/shared/widgets/slot_picker_grid.dart';

class SalonCard extends StatelessWidget {
  const SalonCard({
    super.key,
    required this.salon,
    this.onTap,
    this.onBook,
    this.footerActionLabel,
    this.onFooterAction,
    this.autoPlayImages = true,
    this.cardWidth,
    this.imageHeight = 208,
    this.showPromoChips = false,
    this.compactRating = false,
    this.alwaysShowSubtitle = false,
  });

  final SalonModel salon;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final String? footerActionLabel;
  final VoidCallback? onFooterAction;
  final bool autoPlayImages;
  final double? cardWidth;
  final double imageHeight;
  final bool showPromoChips;
  final bool compactRating;
  final bool alwaysShowSubtitle;

  @override
  Widget build(BuildContext context) {
    final showBook = onBook != null && salon.hasServices;
    final showFooterAction =
        onFooterAction != null && footerActionLabel != null;
    final subtitle = salon.address ?? salon.city;
    final fallbackSubtitle = 'Premium salon experience';
    final ratingSize = compactRating
        ? SalonRatingBadgeSize.compact
        : SalonRatingBadgeSize.regular;
    final memCacheWidth = (cardWidth ?? 400).round() * 2;
    final memCacheHeight = imageHeight.round() * 2;

    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SalonCardImageCarousel(
                  images: salon.carouselImages,
                  height: imageHeight,
                  salonId: salon.id,
                  autoPlay: autoPlayImages,
                  placeholder: _placeholder(),
                  memCacheWidth: memCacheWidth,
                  memCacheHeight: memCacheHeight,
                ),
                if (showPromoChips)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: SalonPromoChips(salon: salon),
                  ),
                if (!showPromoChips &&
                    salon.slotsToday != null &&
                    salon.slotsToday!.total > 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: SlotsAvailabilityBadge(summary: salon.slotsToday),
                  ),
              ],
            ),
          ),
          GlassOverlayPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salon.salonName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (alwaysShowSubtitle || subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle ?? fallbackSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                if (!alwaysShowSubtitle && salon.hasServices) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        size: 14,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          salon.services.isNotEmpty
                              ? '${salon.services.length} services available'
                              : 'Services available',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    SalonDistanceBadge(
                      distanceKm: salon.distanceKm,
                      compact: compactRating,
                    ),
                    const Spacer(),
                    SalonRatingBadge(
                      averageRating: salon.averageRating,
                      reviewCount: salon.reviewCount,
                      size: ratingSize,
                    ),
                  ],
                ),
                if (showBook || showFooterAction) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (showFooterAction)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onFooterAction,
                            icon: const Icon(Icons.build_rounded, size: 16),
                            label: Text(footerActionLabel!),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: BorderSide(
                                color:
                                    AppColors.accent.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      if (showBook && showFooterAction)
                        const SizedBox(width: 8),
                      if (showBook)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onBook,
                            icon: const Icon(Icons.calendar_today_rounded,
                                size: 16),
                            label: const Text('Book'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.backgroundDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(color: AppColors.glowAccent),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.accent.withValues(alpha: 0.06),
          child: cardContent,
        ),
      ),
    );

    if (cardWidth == null) return card;
    return SizedBox(width: cardWidth, child: card);
  }

  Widget _placeholder() => Container(
        height: imageHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surfaceElevated,
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: imageHeight < 200 ? 34 : 36,
              color: AppColors.accent,
            ),
          ),
        ),
      );
}
