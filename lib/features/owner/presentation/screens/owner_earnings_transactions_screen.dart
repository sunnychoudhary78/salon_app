import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';

class OwnerEarningsTransactionsScreen extends ConsumerStatefulWidget {
  const OwnerEarningsTransactionsScreen({super.key});

  @override
  ConsumerState<OwnerEarningsTransactionsScreen> createState() =>
      _OwnerEarningsTransactionsScreenState();
}

class _OwnerEarningsTransactionsScreenState
    extends ConsumerState<OwnerEarningsTransactionsScreen> {
  int _page = 1;

  String _formatEntryType(String type) {
    switch (type) {
      case 'SERVICE_SALON_NET':
        return 'Service earnings';
      case 'PREMIUM_SALON':
        return 'Premium share';
      case 'SERVICE_COMMISSION':
        return 'Platform fee';
      case 'PREMIUM_PLATFORM':
        return 'Platform premium fee';
      default:
        return type.replaceAll('_', ' ').toLowerCase();
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('d MMM yyyy, h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(ownerEarningsTransactionsProvider(_page));
    final colors = context.appColors;

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Transactions',
        subtitle: 'Earnings history',
      ),
      body: GradientBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ownerEarningsTransactionsProvider(_page));
            await ref.read(ownerEarningsTransactionsProvider(_page).future);
          },
          child: AsyncValueWidget(
            value: transactions,
            data: (result) {
              if (result.items.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions yet',
                  subtitle: 'Earnings appear here after customers pay.',
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  AppDecorations.scrollBottomPadding(context),
                ),
                itemCount: result.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == result.items.length) {
                    final totalPages = (result.total / 20).ceil();
                    if (totalPages <= 1) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.glassBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _page > 1
                                  ? () => setState(() => _page -= 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Text(
                              'Page $_page of $totalPages',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              onPressed: _page < totalPages
                                  ? () => setState(() => _page += 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final item = result.items[index];
                  return AnimatedEntrance(
                    index: index,
                    child: _TransactionTile(
                      item: item,
                      label: _formatEntryType(item.entryType),
                      dateLabel: _formatDate(item.createdAt),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.item,
    required this.label,
    required this.dateLabel,
  });

  final OwnerEarningsTransactionModel item;
  final String label;
  final String dateLabel;

  String get _statusLabel {
    switch (item.status.toUpperCase()) {
      case 'COLLECTED':
        return 'At salon';
      case 'SETTLED':
        return 'Settled';
      case 'IN_BATCH':
        return 'Processing';
      case 'PENDING':
        return 'Pending';
      default:
        return item.status;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (item.status.toUpperCase()) {
      case 'COLLECTED':
        return context.appColors.accent;
      case 'SETTLED':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = _statusColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        elevated: true,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.payments_outlined,
                color: colors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${item.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _statusLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
