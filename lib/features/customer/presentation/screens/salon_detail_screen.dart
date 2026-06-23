import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/core/utils/salon_time_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/salon_cube_image_slider.dart';
import 'package:saloon_booking/shared/widgets/salon_distance_badge.dart';
import 'package:saloon_booking/shared/widgets/salon_rating_badge.dart';
import 'package:saloon_booking/shared/widgets/screen_action_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/service_tile.dart';

class SalonDetailScreen extends ConsumerWidget {
  const SalonDetailScreen({super.key, required this.salonId});

  final String salonId;

  Map<String, List<ServiceModel>> _groupByCategory(SalonModel salon) {
    final map = <String, List<ServiceModel>>{};
    for (final service in salon.services) {
      final key = service.category?.name ?? 'General';
      map.putIfAbsent(key, () => []).add(service);
    }
    return map;
  }

  double? _minServicePrice(SalonModel salon) {
    if (salon.services.isEmpty) return null;
    return salon.services
        .map((s) => s.effectivePrice)
        .reduce((a, b) => a < b ? a : b);
  }

  void _openBooking(BuildContext context, {String? serviceId}) {
    final base = '${RoutePaths.customerSalons}/$salonId/book';
    if (serviceId != null && serviceId.isNotEmpty) {
      context.push('$base?serviceId=$serviceId');
    } else {
      context.push(base);
    }
  }

  Future<void> _callSalon(BuildContext context, String phone) async {
    final launched = await launchPhoneCall(phone);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(salonDetailProvider(salonId));
    final reviewsAsync = ref.watch(salonReviewsProvider(salonId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) popOrGoHome(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: AsyncValueWidget(
          value: salonAsync,
          data: (salon) {
            final grouped = _groupByCategory(salon);
            final hasPhone =
                salon.phone != null && salon.phone!.trim().isNotEmpty;
            final hoursLabel = salon.openingTime != null &&
                    salon.closingTime != null
                ? '${formatSalonTimeDisplay(salon.openingTime)} – ${formatSalonTimeDisplay(salon.closingTime)}'
                : null;
            final locationLine = [
              if (salon.city != null) salon.city,
              if (salon.state != null) salon.state,
            ].join(', ');

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: salon.allDisplayImages.isNotEmpty ? 280 : 120,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.9),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => popOrGoHome(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 56,
                      bottom: 16,
                      end: 16,
                    ),
                    title: Text(
                      salon.salonName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    background: salon.allDisplayImages.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              if (salon.allDisplayImages.length == 1)
                                CachedNetworkImage(
                                  imageUrl: resolveImageUrl(
                                    salon.allDisplayImages.first,
                                  ),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _heroPlaceholder(),
                                )
                              else
                                SalonCubeImageSlider(
                                  images: salon.allDisplayImages,
                                  height: 280,
                                  borderRadius: BorderRadius.zero,
                                ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.35),
                                      Colors.transparent,
                                      AppColors.backgroundDark
                                          .withValues(alpha: 0.92),
                                    ],
                                    stops: const [0, 0.45, 1],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                bottom: 56,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    SalonRatingBadge(
                                      averageRating: salon.averageRating,
                                      reviewCount: salon.reviewCount,
                                      size: SalonRatingBadgeSize.large,
                                    ),
                                    SalonDistanceBadge(
                                      distanceKm: salon.distanceKm,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.35),
                                  AppColors.backgroundDark,
                                ],
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 56),
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    SalonRatingBadge(
                                      averageRating: salon.averageRating,
                                      reviewCount: salon.reviewCount,
                                      size: SalonRatingBadgeSize.large,
                                    ),
                                    SalonDistanceBadge(
                                      distanceKm: salon.distanceKm,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      GlassCard(
                        child: Column(
                          children: [
                            if (locationLine.isNotEmpty || salon.address != null)
                              _InfoRow(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                value: salon.address?.isNotEmpty == true
                                    ? '${salon.address}\n$locationLine'
                                    : locationLine,
                              ),
                            if (hoursLabel != null)
                              _InfoRow(
                                icon: Icons.schedule_rounded,
                                label: 'Hours',
                                value: hoursLabel,
                              ),
                            if (hasPhone)
                              _InfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: salon.phone!,
                                trailing: _SalonCallButton(
                                  onTap: () =>
                                      _callSalon(context, salon.phone!),
                                ),
                              ),
                            if (salon.description != null &&
                                salon.description!.isNotEmpty)
                              _InfoRow(
                                icon: Icons.info_outline_rounded,
                                label: 'About',
                                value: salon.description!,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SectionHeader(
                        title: 'Services',
                        subtitle: salon.services.isEmpty
                            ? null
                            : 'Tap a service to book it directly',
                      ),
                      const SizedBox(height: 12),
                      if (salon.services.isEmpty)
                        const EmptyState(
                          icon: Icons.spa_outlined,
                          title: 'No services yet',
                          subtitle: 'Check back later for available treatments.',
                          compact: true,
                        )
                      else
                        ...grouped.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...entry.value.map(
                                    (service) => ServiceTile(
                                      service: service,
                                      showBookAffordance: true,
                                      onTap: () => _openBooking(
                                        context,
                                        serviceId: service.id,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 28),
                      SectionHeader(
                        title: 'Customer reviews',
                        subtitle: salon.reviewCount > 0
                            ? '${salon.reviewCount} review${salon.reviewCount == 1 ? '' : 's'}'
                            : 'Be the first after your visit',
                      ),
                      const SizedBox(height: 12),
                      AsyncValueWidget(
                        value: reviewsAsync,
                        data: (result) {
                          if (result.reviews.isEmpty) {
                            return const EmptyState(
                              icon: Icons.rate_review_outlined,
                              title: 'No reviews yet',
                              subtitle:
                                  'Book an appointment and share your experience.',
                              compact: true,
                            );
                          }

                          return Column(
                            children: result.reviews.map((review) {
                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.25),
                                      child: Text(
                                        (review.customerName ?? 'C')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  review.customerName ??
                                                      'Customer',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall,
                                                ),
                                              ),
                                              if (review.createdAt != null)
                                                Text(
                                                  _relativeDate(
                                                    review.createdAt!,
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color:
                                                            AppColors.textMuted,
                                                      ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          ReviewStarsRow(
                                            rating: review.rating,
                                          ),
                                          if (review.review != null &&
                                              review.review!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(review.review!),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: salonAsync.maybeWhen(
          data: (salon) {
            if (salon.services.isEmpty) return null;
            final minPrice = _minServicePrice(salon);
            final label = minPrice != null
                ? 'Book appointment · from ₹${minPrice.toStringAsFixed(0)}'
                : 'Book appointment';
            return ScreenActionBar(
              label: label,
              icon: Icons.calendar_today_rounded,
              onPressed: () => _openBooking(context),
            );
          },
          orElse: () => null,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

Widget _heroPlaceholder() {
  return Container(
    color: AppColors.glassFill,
    child: const Center(
      child: Icon(Icons.store_rounded, size: 48, color: AppColors.textMuted),
    ),
  );
}

class _SalonCallButton extends StatelessWidget {
  const _SalonCallButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent.withValues(alpha: 0.95),
                AppColors.primary.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: const Icon(
            Icons.phone_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
