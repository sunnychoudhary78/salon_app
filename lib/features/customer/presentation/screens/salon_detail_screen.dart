import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/core/utils/salon_time_utils.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/salon_cube_image_slider.dart';
import 'package:saloon_booking/shared/widgets/salon_distance_badge.dart';
import 'package:saloon_booking/shared/widgets/salon_rating_badge.dart';
import 'package:saloon_booking/shared/widgets/screen_action_bar.dart';
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

  void _openBooking(BuildContext context) {
    context.push('${RoutePaths.customerSalons}/$salonId/book');
  }

  Future<void> _callSalon(BuildContext context, String phone) async {
    final launched = await launchPhoneCall(phone);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(salonDetailProvider(salonId));
    final reviewsAsync = ref.watch(salonReviewsProvider(salonId));
    final appBarTitle = salonAsync.maybeWhen(
      data: (salon) => salon.salonName,
      orElse: () => 'Salon details',
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) popOrGoHome(context);
      },
      child: Scaffold(
        appBar: PremiumAppBar(
          title: appBarTitle,
          showMenu: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => popOrGoHome(context),
          ),
        ),
        body: AsyncValueWidget(
          value: salonAsync,
          data: (salon) {
            final grouped = _groupByCategory(salon);
            final hasPhone = salon.phone != null && salon.phone!.trim().isNotEmpty;
            final hoursLabel = salon.openingTime != null && salon.closingTime != null
                ? '${formatSalonTimeDisplay(salon.openingTime)} – ${formatSalonTimeDisplay(salon.closingTime)}'
                : null;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (salon.allDisplayImages.isNotEmpty)
                  SalonCubeImageSlider(images: salon.allDisplayImages),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SalonRatingBadge(
                                  averageRating: salon.averageRating,
                                  reviewCount: salon.reviewCount,
                                  size: SalonRatingBadgeSize.large,
                                ),
                                SalonDistanceBadge(distanceKm: salon.distanceKm),
                              ],
                            ),
                          ),
                          if (hasPhone) ...[
                            const SizedBox(width: 12),
                            _SalonCallButton(
                              onTap: () => _callSalon(context, salon.phone!),
                            ),
                          ],
                        ],
                      ),
                      if (salon.city != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${salon.city}${salon.state != null ? ', ${salon.state}' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                      if (salon.address != null) Text(salon.address!),
                      if (hoursLabel != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: AppColors.accent.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hoursLabel,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      if (salon.description != null) ...[
                        const SizedBox(height: 12),
                        Text(salon.description!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Services', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (salon.services.isEmpty)
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.accent.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No services available yet — check back later',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...grouped.entries.expand((entry) sync* {
                    yield Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                    yield const SizedBox(height: 4);
                    for (final service in entry.value) {
                      yield ServiceTile(
                        service: service,
                        onTap: () => _openBooking(context),
                      );
                    }
                    yield const SizedBox(height: 12);
                  }),
                const SizedBox(height: 24),
                Text('Customer reviews', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                AsyncValueWidget(
                  value: reviewsAsync,
                  data: (result) {
                    if (result.reviews.isEmpty) {
                      return GlassCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              color: AppColors.accent.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No reviews yet — be the first after your visit',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: result.reviews.map((review) {
                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ReviewStarsRow(rating: review.rating),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      review.customerName ?? 'Customer',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                  if (review.createdAt != null)
                                    Text(
                                      DateFormat.yMMMd().format(review.createdAt!),
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                ],
                              ),
                              if (review.review != null && review.review!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(review.review!),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: salonAsync.maybeWhen(
          data: (salon) => salon.services.isNotEmpty
              ? ScreenActionBar(
                  label: 'Book appointment',
                  icon: Icons.calendar_today_rounded,
                  onPressed: () => _openBooking(context),
                )
              : null,
          orElse: () => null,
        ),
      ),
    );
  }
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
          width: 48,
          height: 48,
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
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.phone_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
