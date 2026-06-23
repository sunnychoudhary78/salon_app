import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerReviewsScreen extends ConsumerStatefulWidget {
  const OwnerReviewsScreen({super.key});

  @override
  ConsumerState<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends ConsumerState<OwnerReviewsScreen> {
  String? _salonFilter;

  String _relativeDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(ownerReviewsProvider);

    return Scaffold(
      appBar: const PremiumAppBar(title: 'Reviews'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ownerReviewsProvider),
        child: AsyncValueWidget(
          value: reviews,
          data: (items) {
            final salonNames = items
                .map((r) => r.salonName)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort();

            final filtered = _salonFilter == null
                ? items
                : items.where((r) => r.salonName == _salonFilter).toList();

            if (items.isEmpty) {
              return const EmptyStateScrollable(
                child: EmptyState(
                  icon: Icons.star_outline_rounded,
                  title: 'No reviews yet',
                  subtitle:
                      'Reviews from customers will appear here after their visits.',
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                AppDecorations.shellBottomInset,
              ),
              children: [
                const SectionHeader(
                  title: 'Customer feedback',
                  subtitle: 'Ratings from your salon visits',
                ),
                if (salonNames.length > 1) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All salons',
                          selected: _salonFilter == null,
                          onTap: () => setState(() => _salonFilter = null),
                        ),
                        ...salonNames.map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                              label: name,
                              selected: _salonFilter == name,
                              onTap: () =>
                                  setState(() => _salonFilter = name),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No reviews for this salon',
                    compact: true,
                  )
                else
                  ...filtered.map((review) {
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.2),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        review.customerName ?? 'Customer',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ),
                                    if (review.createdAt != null)
                                      Text(
                                        _relativeDate(review.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(
                                    5,
                                    (j) => Icon(
                                      j < review.rating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 16,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                if (review.salonName != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    review.salonName!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: AppColors.accent),
                                  ),
                                ],
                                if (review.review != null) ...[
                                  const SizedBox(height: 6),
                                  Text(review.review!),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
        color: selected ? AppColors.accent : AppColors.textSecondary,
      ),
    );
  }
}
