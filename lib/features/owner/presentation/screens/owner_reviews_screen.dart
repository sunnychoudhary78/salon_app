import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';

class OwnerReviewsScreen extends ConsumerWidget {
  const OwnerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(ownerReviewsProvider);

    return Scaffold(
      appBar: const PremiumAppBar(title: 'Reviews'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ownerReviewsProvider),
        child: AsyncValueWidget(
          value: reviews,
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No reviews yet')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final review = items[i];
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (j) => Icon(
                              j < review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 18,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              review.customerName ?? 'Customer',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      if (review.salonName != null) ...[
                        const SizedBox(height: 6),
                        Text(review.salonName!),
                      ],
                      if (review.review != null) ...[
                        const SizedBox(height: 4),
                        Text(review.review!),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
