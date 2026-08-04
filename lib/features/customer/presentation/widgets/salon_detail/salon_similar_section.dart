import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_helpers.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_section.dart';
import 'package:saloon_booking/shared/widgets/salon_card.dart';

class SalonSimilarSection extends ConsumerWidget {
  const SalonSimilarSection({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonsAsync = ref.watch(paginatedSalonsProvider);
    return salonsAsync.when(
      data: (state) {
        final similar = similarSalons(state.items, salonId);
        if (similar.length < 2) return const SizedBox.shrink();

        return SalonDetailSection(
          title: 'Similar Salons',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < similar.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    SalonCard(
                      salon: similar[i],
                      cardWidth: 238,
                      imageHeight: 118,
                      compactRating: true,
                      onTap: () => context.push(
                        '${RoutePaths.customerSalons}/${similar[i].id}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
