import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/glass_bottom_sheet.dart';

Future<void> showOwnerDashboardPeriodSheet(BuildContext context) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (ctx) => const _OwnerDashboardPeriodSheet(),
  );
}

class OwnerDashboardPeriodButton extends ConsumerWidget {
  const OwnerDashboardPeriodButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(ownerDashboardPeriodProvider);
    final showIndicator = selected != OwnerDashboardPeriod.last7Days;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.date_range_rounded),
          tooltip: 'Time range',
          onPressed: () => showOwnerDashboardPeriodSheet(context),
        ),
        if (showIndicator)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.appColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _OwnerDashboardPeriodSheet extends ConsumerWidget {
  const _OwnerDashboardPeriodSheet();

  IconData _iconFor(OwnerDashboardPeriod period) => switch (period) {
    OwnerDashboardPeriod.last7Days => Icons.today_rounded,
    OwnerDashboardPeriod.last30Days => Icons.date_range_rounded,
    OwnerDashboardPeriod.lifetime => Icons.all_inclusive_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final selected = ref.watch(ownerDashboardPeriodProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Time range',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how earnings and charts are calculated',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 16),
          ...OwnerDashboardPeriod.values.map((period) {
            final isSelected = selected == period;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _iconFor(period),
                color: isSelected
                    ? context.appColors.accent
                    : colors.textSecondary,
              ),
              title: Text(
                period.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: context.appColors.accent)
                  : null,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(ownerDashboardPeriodProvider.notifier).select(period);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
