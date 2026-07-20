import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
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
    this.autoPlayImages = false,
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
    final colors = context.appColors;
    final showBook = onBook != null && salon.hasServices;
    final showFooterAction =
        onFooterAction != null && footerActionLabel != null;
    final subtitle =
        salon.formattedAddress ?? salon.address ?? salon.city;
    final fallbackSubtitle = 'Premium salon experience';
    final ratingSize = compactRating
        ? SalonRatingBadgeSize.compact
        : SalonRatingBadgeSize.regular;
    final width = cardWidth ?? MediaQuery.sizeOf(context).width - 32;
    final memCacheWidth = (width.clamp(200.0, 480.0) * 1.5).round();
    final memCacheHeight = (imageHeight * 1.5).round();

    final infoSection = GlassOverlayPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            salon.salonName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
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
                    color: colors.textSecondary,
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
          if (salon.slotsToday != null && salon.slotsToday!.shouldShowOnCard) ...[
            const SizedBox(height: 8),
            SlotsAvailabilityInfoLine(summary: salon.slotsToday!),
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
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                if (showBook && showFooterAction) const SizedBox(width: 8),
                if (showBook)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onBook,
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: const Text('Book'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: context.appColors.onAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

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
                  placeholder: _placeholder(context),
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
                if (salon.slotsToday != null && salon.slotsToday!.shouldShowOnCard)
                  Positioned(
                    top: showPromoChips ? null : 12,
                    bottom: showPromoChips ? 12 : null,
                    left: 12,
                    child: SlotsAvailabilityBadge(summary: salon.slotsToday),
                  ),
              ],
            ),
          ),
          if (onTap != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: infoSection,
              ),
            )
          else
            infoSection,
        ],
      ),
    );

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: colors.cardShadow(color: colors.glowAccent),
        border: Border.all(
          color: colors.glassBorder.withValues(alpha: 0.35),
        ),
      ),
      child: cardContent,
    );

    if (cardWidth == null) return card;
    return SizedBox(width: cardWidth, child: card);
  }

  Widget _placeholder(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: imageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            colors.surfaceElevated,
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.glassFill,
            shape: BoxShape.circle,
            border: Border.all(color: colors.glassBorder),
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
}
