import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/dio_client.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/payments/presentation/providers/payment_provider.dart';
import 'package:saloon_booking/core/utils/booking_timeline_utils.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/booking_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class CustomerBookingsScreen extends ConsumerStatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  ConsumerState<CustomerBookingsScreen> createState() =>
      _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState
    extends ConsumerState<CustomerBookingsScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _remainingLabel(DateTime? expiresAt) {
    if (expiresAt == null) return 'Pay now to confirm this premium booking';
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Premium payment window expired';
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    if (remaining.inHours > 0) {
      return 'Premium payment due in ${remaining.inHours}:$minutes:$seconds';
    }
    return 'Premium payment due in $minutes:$seconds';
  }

  Future<void> _runPaymentAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.apiException.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _bookingActions(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) {
    final paymentLoading = ref.watch(paymentActionsProvider).isLoading;
    final actions = <Widget>[];

    if (booking.needsPremiumPayment) {
      actions.add(
        Text(
          _remainingLabel(booking.premiumPayment?.expiresAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      actions.add(
        PremiumButton(
          label: 'Pay premium',
          expand: false,
          size: PremiumButtonSize.small,
          loading: paymentLoading,
          onPressed: paymentLoading
              ? null
              : () => _runPaymentAction(
                  context,
                  () => ref
                      .read(paymentActionsProvider.notifier)
                      .payOnline(booking: booking, paymentType: 'PREMIUM_FEE'),
                  'Premium payment successful',
                ),
        ),
      );
    } else if (booking.premiumPaymentExpired) {
      actions.add(
        Text(
          'Premium payment window expired',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (booking.canChooseSalonPayment) {
      actions.add(
        PremiumButton(
          label: 'Pay online',
          expand: false,
          size: PremiumButtonSize.small,
          loading: paymentLoading,
          onPressed: paymentLoading
              ? null
              : () => _runPaymentAction(
                  context,
                  () => ref
                      .read(paymentActionsProvider.notifier)
                      .payOnline(booking: booking, paymentType: 'SALON_FEE'),
                  'Payment successful',
                ),
        ),
      );
      actions.add(
        PremiumButton(
          label: 'Pay at shop',
          expand: false,
          size: PremiumButtonSize.small,
          variant: PremiumButtonVariant.ghost,
          onPressed: paymentLoading
              ? null
              : () => _runPaymentAction(
                  context,
                  () => ref
                      .read(paymentActionsProvider.notifier)
                      .selectPayAtShop(booking.id),
                  'Pay at shop selected',
                ),
        ),
      );
    }

    if (booking.canCancel) {
      actions.add(
        PremiumButton(
          label: 'Cancel',
          expand: false,
          size: PremiumButtonSize.small,
          variant: PremiumButtonVariant.ghost,
          onPressed: () async {
            await ref.read(bookingActionsProvider.notifier).cancel(booking.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled')),
              );
            }
          },
        ),
      );
    }

    if (booking.hasReview) {
      actions.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.35),
            ),
          ),
          child: const Text(
            'Reviewed',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    if (booking.canReview) {
      actions.add(
        PremiumButton(
          label: 'Review',
          expand: false,
          size: PremiumButtonSize.small,
          variant: PremiumButtonVariant.accent,
          onPressed: () => context.push(
            '${RoutePaths.customerBookings}/${booking.id}/review',
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: actions,
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    List<BookingModel> items, {
    required bool isActiveTab,
  }) {
    if (items.isEmpty) {
      return EmptyStateScrollable(
        child: EmptyState(
          icon: isActiveTab
              ? Icons.event_available_outlined
              : Icons.history_rounded,
          title: isActiveTab ? 'No active bookings' : 'No past bookings',
          subtitle: isActiveTab
              ? 'Upcoming and pending appointments will appear here.'
              : 'Completed, cancelled, and declined visits show up here.',
          actionLabel: isActiveTab ? 'Explore salons' : null,
          onAction: isActiveTab
              ? () => context.go(RoutePaths.customerHome)
              : null,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        AppDecorations.shellBottomInset,
      ),
      children: [
        SectionHeader(
          title: isActiveTab ? 'Active appointments' : 'Past appointments',
          subtitle:
              '${items.length} booking${items.length == 1 ? '' : 's'}',
        ),
        const SizedBox(height: 14),
        ...items.map(
          (booking) => BookingCard(
            booking: booking,
            trailing: _bookingActions(context, ref, booking),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'My bookings',
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
                final activeCount = customerActiveBookings(items).length;
                final pastCount = customerPastBookings(items).length;
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
              onRefresh: () async => ref.invalidate(myBookingsProvider),
              child: AsyncValueWidget(
                value: bookings,
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        AppDecorations.shellBottomInset,
                      ),
                      children: [
                        EmptyView(
                          message:
                              'No bookings yet — discover a salon and book your first appointment',
                          icon: Icons.calendar_month_outlined,
                          action: () => context.go(RoutePaths.customerHome),
                          actionLabel: 'Explore salons',
                        ),
                      ],
                    );
                  }

                  final active = customerActiveBookings(items);
                  final past = customerPastBookings(items);

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingList(context, active, isActiveTab: true),
                      _buildBookingList(context, past, isActiveTab: false),
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
}
