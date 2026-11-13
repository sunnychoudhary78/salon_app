import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/image_url_utils.dart';
import 'package:saloon_booking/features/ai_stylist/data/models/ai_stylist_models.dart';

class RecommendedSalonsStrip extends StatelessWidget {
  const RecommendedSalonsStrip({super.key, required this.salons});

  final List<RecommendedSalonItem> salons;

  @override
  Widget build(BuildContext context) {
    if (salons.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Nearby Salons for this Look',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: salons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final salon = salons[index];
              final firstService = salon.matchedServices.isNotEmpty
                  ? salon.matchedServices.first
                  : null;
              final serviceIdsParam = salon.matchedServices
                  .take(2)
                  .map((s) => s.id)
                  .where((id) => id.isNotEmpty)
                  .join(',');

              return Container(
                width: 228,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: salon.coverImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: resolveImageUrl(salon.coverImageUrl!),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _SalonThumbPlaceholder(colors: colors),
                                )
                              : _SalonThumbPlaceholder(colors: colors),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                salon.salonName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (salon.averageRating != null) ...[
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: AppColors.starGold,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      salon.averageRating!.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (salon.distanceKm != null)
                                    Text(
                                      '${salon.distanceKm!.toStringAsFixed(1)} km',
                                      style: TextStyle(
                                        color: colors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (firstService != null)
                      Text(
                        '${firstService.serviceName} • ₹${firstService.effectivePrice.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              context.push('${RoutePaths.customerSalons}/${salon.id}');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              side: BorderSide(color: colors.glassBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'View',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final query = serviceIdsParam.isNotEmpty
                                  ? '?serviceIds=$serviceIdsParam'
                                  : '';
                              context.push(
                                '${RoutePaths.customerSalons}/${salon.id}/book$query',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Book',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SalonThumbPlaceholder extends StatelessWidget {
  const _SalonThumbPlaceholder({required this.colors});
  final AppThemeExtension colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: colors.surfaceSunken,
      child: Icon(Icons.storefront_rounded, color: colors.textMuted, size: 20),
    );
  }
}
