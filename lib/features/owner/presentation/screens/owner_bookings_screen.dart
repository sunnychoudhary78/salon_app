import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/shell_navigation_scope.dart';
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
  static const _statuses = ['PENDING', 'ACCEPTED', 'COMPLETED'];

  String _tabLabel(String status) => switch (status) {
        'PENDING' => 'Requests',
        _ => status[0] + status.substring(1).toLowerCase(),
      };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shellNav = ShellNavigationScope.maybeOf(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: shellNav != null,
        title: Text(
          'Bookings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        backgroundColor: Colors.transparent,
        leading: shellNav != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: shellNav.openDrawer,
                tooltip: 'Open menu',
              )
            : null,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: _statuses.map((s) => Tab(text: _tabLabel(s))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) {
          final bookings = ref.watch(ownerBookingsProvider(status));
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(ownerBookingsProvider(status)),
            child: AsyncValueWidget(
              value: bookings,
              data: (items) {
                if (items.isEmpty) {
                  return ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(child: Text('No ${_tabLabel(status).toLowerCase()} bookings')),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final booking = items[i];
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    booking.customer?.name ?? 'Customer',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                StatusBadge(status: booking.bookingStatus),
                                if (booking.isPremium) ...[
                                  const SizedBox(width: 6),
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
                              ],
                            ),
                            Text(booking.serviceName ?? 'Service'),
                            if (booking.salonName != null &&
                                booking.salonName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                booking.salonName!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                            Text('${booking.bookingDate} ${booking.bookingTime}'),
                            if (booking.customer?.phone != null)
                              Text(booking.customer!.phone!),
                            const SizedBox(height: 8),
                            if (status == 'PENDING') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: PremiumButton(
                                      label: 'Accept',
                                      expand: true,
                                      onPressed: () async {
                                        await ref
                                            .read(ownerBookingActionsProvider)
                                            .accept(booking.id);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Booking accepted'),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: PremiumButton(
                                      label: 'Reject',
                                      variant: PremiumButtonVariant.ghost,
                                      expand: true,
                                      onPressed: () => _reject(booking.id),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (status == 'ACCEPTED')
                              PremiumButton(
                                label: 'Mark completed',
                                onPressed: () => ref
                                    .read(ownerBookingActionsProvider)
                                    .complete(booking.id),
                              ),
                          ],
                        ),
                    );
                  },
                );
              },
            ),
          );
        }).toList(),
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
