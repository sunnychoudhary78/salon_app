import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_helpers.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/salon_detail/salon_detail_section.dart';

class SalonWhyChooseSection extends StatelessWidget {
  const SalonWhyChooseSection({super.key, required this.salon});

  final SalonModel salon;

  @override
  Widget build(BuildContext context) {
    final itemsByTitle = <String, SalonWhyChooseItem>{
      for (final item in whyChooseItems(salon)) item.title: item,
    };
    final items = itemsByTitle.values.toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return SalonDetailSection(
      title: 'Highlights',
      child: SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          clipBehavior: Clip.none,
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return _HighlightCard(item: item);
          },
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.item});

  final SalonWhyChooseItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 176,
      padding: const EdgeInsets.all(12),
      decoration: compactSalonDetailCardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.appColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: context.appColors.accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.25,
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
