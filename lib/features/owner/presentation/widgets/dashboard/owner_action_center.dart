import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_profile_completion_nav.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/premium_chip.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';

class OwnerActionCenter extends StatefulWidget {
  const OwnerActionCenter({
    super.key,
    required this.attention,
    this.previewLimit = 2,
  });

  final OwnerDashboardAttention attention;
  final int previewLimit;

  @override
  State<OwnerActionCenter> createState() => _OwnerActionCenterState();
}

class _OwnerActionCenterState extends State<OwnerActionCenter> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = _collectItems();
    if (items.isEmpty) return const SizedBox.shrink();

    final visible = _expanded ? items : items.take(widget.previewLimit).toList();
    final hasMore = items.length > widget.previewLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Text(
              'Needs attention (${items.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...visible.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActionRow(
                entry: entry,
                onTap: () => _handleTap(context, entry),
              ),
            )),
        if (hasMore && !_expanded)
          TextButton(
            onPressed: () => setState(() => _expanded = true),
            child: Text('View all (${items.length})'),
          ),
      ],
    );
  }

  List<_ActionEntry> _collectItems() {
    const priority = {
      'cash_confirmations_pending': 0,
      'premium_unpaid': 1,
      'pending_bookings': 2,
    };

    const excludedTypes = {'payout_account', 'profile_completeness'};

    final sections = widget.attention.sections
        .where((s) => !excludedTypes.contains(s.type))
        .toList()
      ..sort((a, b) {
        final pa = priority[a.type] ?? 99;
        final pb = priority[b.type] ?? 99;
        if (pa != pb) return pa.compareTo(pb);
        return b.count.compareTo(a.count);
      });

    final entries = <_ActionEntry>[];
    for (final section in sections) {
      if (section.count == 0) continue;
      for (final item in section.items) {
        entries.add(_ActionEntry(section: section, item: item));
      }
    }
    return entries;
  }

  void _handleTap(BuildContext context, _ActionEntry entry) {
    switch (entry.section.type) {
      case 'pending_bookings':
      case 'cash_confirmations_pending':
      case 'premium_unpaid':
        context.go(RoutePaths.ownerBookings);
      case 'payout_account':
        context.push(RoutePaths.ownerPayoutAccount);
      case 'profile_completeness':
        navigateToProfileGapFromAttention(
          context,
          salonId: entry.item.salonId,
          missing: entry.item.missing,
        );
      default:
        context.go(RoutePaths.ownerBookings);
    }
  }
}

class _ActionEntry {
  const _ActionEntry({required this.section, required this.item});

  final OwnerDashboardAttentionSection section;
  final OwnerDashboardAttentionItem item;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.entry, required this.onTap});

  final _ActionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final section = entry.section;
    final item = entry.item;
    final isPremiumUnpaid = section.type == 'premium_unpaid';
    final isPremium = item.isPremium || isPremiumUnpaid;

    final title = _titleFor(entry);
    final subtitle = _subtitleFor(entry);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Container(
        decoration: isPremiumUnpaid
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.accent, width: 4),
                ),
              )
            : null,
        padding: isPremiumUnpaid
            ? const EdgeInsets.only(left: 8)
            : EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: 6),
                        const PremiumChip(compact: true),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _actionLabel(section.type),
          ],
        ),
      ),
    );
  }

  String _titleFor(_ActionEntry entry) {
    final item = entry.item;
    switch (entry.section.type) {
      case 'pending_bookings':
        return item.customerName ?? 'Pending booking';
      case 'cash_confirmations_pending':
        return item.customerName ?? 'Cash confirmation';
      case 'premium_unpaid':
        return item.customerName ?? 'Premium unpaid';
      case 'payout_account':
        return item.message ?? 'Payout account';
      case 'profile_completeness':
        return item.salonName ?? 'Complete profile';
      default:
        return item.customerName ?? 'Attention needed';
    }
  }

  String? _subtitleFor(_ActionEntry entry) {
    final item = entry.item;
    switch (entry.section.type) {
      case 'pending_bookings':
      case 'premium_unpaid':
        final time = _formatTime(item.bookingTime);
        final date = item.bookingDate ?? '';
        if (time.isNotEmpty && date.isNotEmpty) return '$date · $time';
        return item.salonName;
      case 'cash_confirmations_pending':
        if (item.amount != null) return '₹${item.amount!.toStringAsFixed(0)}';
        return item.salonName;
      case 'profile_completeness':
        if (item.completenessPercent != null) {
          return '${item.completenessPercent}% complete';
        }
        return null;
      default:
        return item.salonName;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  Widget _actionLabel(String type) {
    final label = switch (type) {
      'pending_bookings' => 'Review',
      'cash_confirmations_pending' => 'Confirm',
      'premium_unpaid' => 'Collect',
      'payout_account' => 'Fix',
      'profile_completeness' => 'Complete',
      _ => 'View',
    };
    return Text(
      label,
      style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}
