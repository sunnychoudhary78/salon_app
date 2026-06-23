import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/booking_timeline_utils.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/booking_when_badge.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/status_badge.dart';

class OwnerBookingsScreen extends ConsumerStatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  ConsumerState<OwnerBookingsScreen> createState() =>
      _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showBookingDetail(OwnerBookingModel booking) async {
    final status = booking.bookingStatus.toUpperCase();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.paddingOf(ctx).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.customer?.name ?? 'Customer',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
                StatusBadge(status: booking.bookingStatus),
              ],
            ),
            if (booking.bookingNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                '#${booking.bookingNumber}',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.spa_outlined,
              label: 'Service',
              value: booking.serviceName ?? '—',
            ),
            if (booking.salonName != null)
              _DetailRow(
                icon: Icons.store_outlined,
                label: 'Salon',
                value: booking.salonName!,
              ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date & time',
              value: '${booking.bookingDate} · ${booking.bookingTime}',
            ),
            if (booking.customer?.phone != null)
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: booking.customer!.phone!,
              ),
            if (booking.isPremium) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Urgent booking'
                  '${booking.premiumAmount != null ? ' · ₹${booking.premiumAmount!.toStringAsFixed(0)} premium' : ''}',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                ),
              ),
            ],
            if (status == 'PENDING') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PremiumButton(
                      label: 'Accept',
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(ownerBookingActionsProvider)
                            .accept(booking.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking accepted')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PremiumButton(
                      label: 'Reject',
                      variant: PremiumButtonVariant.ghost,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _reject(booking.id);
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'ACCEPTED') ...[
              const SizedBox(height: 20),
              PremiumButton(
                label: 'Mark completed',
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(ownerBookingActionsProvider)
                      .complete(booking.id);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(OwnerBookingModel booking) {
    final status = booking.bookingStatus.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () => _showBookingDetail(booking),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    (booking.customer?.name ?? 'C').substring(0, 1).toUpperCase(),
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
                      Text(
                        booking.customer?.name ?? 'Customer',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        booking.serviceName ?? 'Service',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: booking.bookingStatus),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.accent.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.bookingDate} · ${booking.bookingTime}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                BookingWhenBadge(
                  date: booking.bookingDate,
                  time: booking.bookingTime,
                  compact: true,
                ),
                if (booking.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (booking.salonName != null) ...[
              const SizedBox(height: 6),
              Text(
                booking.salonName!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.accent,
                    ),
              ),
            ],
            if (status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PremiumButton(
                      label: 'Accept',
                      size: PremiumButtonSize.small,
                      onPressed: () async {
                        await ref
                            .read(ownerBookingActionsProvider)
                            .accept(booking.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking accepted')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PremiumButton(
                      label: 'Reject',
                      size: PremiumButtonSize.small,
                      variant: PremiumButtonVariant.ghost,
                      onPressed: () => _reject(booking.id),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'ACCEPTED')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: PremiumButton(
                  label: 'Mark completed',
                  size: PremiumButtonSize.small,
                  onPressed: () => ref
                      .read(ownerBookingActionsProvider)
                      .complete(booking.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveList(List<OwnerBookingModel> items) {
    if (items.isEmpty) {
      return const EmptyStateScrollable(
        child: EmptyState(
          icon: Icons.event_available_outlined,
          title: 'No active bookings',
          subtitle:
              'Pending requests and upcoming appointments will appear here.',
        ),
      );
    }

    final pending = ownerPendingBookings(items);
    final upcoming = ownerUpcomingAcceptedBookings(items);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        AppDecorations.shellBottomInset,
      ),
      children: [
        if (pending.isNotEmpty) ...[
          SectionHeader(
            title: 'Needs your response',
            subtitle: '${pending.length} pending request${pending.length == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 12),
          ...pending.map(_buildBookingCard),
          const SizedBox(height: 20),
        ],
        if (upcoming.isNotEmpty) ...[
          SectionHeader(
            title: 'Upcoming appointments',
            subtitle: '${upcoming.length} confirmed booking${upcoming.length == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 12),
          ...upcoming.map(_buildBookingCard),
        ],
      ],
    );
  }

  Widget _buildPastList(List<OwnerBookingModel> items) {
    if (items.isEmpty) {
      return const EmptyStateScrollable(
        child: EmptyState(
          icon: Icons.history_rounded,
          title: 'No past bookings',
          subtitle:
              'Completed, cancelled, and rejected appointments appear here.',
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
        SectionHeader(
          title: 'Past appointments',
          subtitle: '${items.length} booking${items.length == 1 ? '' : 's'}',
        ),
        const SizedBox(height: 12),
        ...items.map(_buildBookingCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(ownerAllBookingsProvider);

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Bookings',
        subtitle: 'Active and past appointments',
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: bookings.maybeWhen(
              data: (items) {
                final activeCount = ownerActiveBookings(items).length;
                final pastCount = ownerPastBookings(items).length;
                return [
                  Tab(text: 'Active ($activeCount)'),
                  Tab(text: 'Past ($pastCount)'),
                ];
              },
              orElse: () => const [
                Tab(text: 'Active'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ownerAllBookingsProvider);
              },
              child: AsyncValueWidget(
                value: bookings,
                data: (items) {
                  final active = ownerActiveBookings(items);
                  final past = ownerPastBookings(items);
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActiveList(active),
                      _buildPastList(past),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reject(String bookingId) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject booking'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    await ref.read(ownerBookingActionsProvider).reject(
          bookingId,
          reason: reason.isEmpty ? null : reason,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking rejected')),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
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
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
