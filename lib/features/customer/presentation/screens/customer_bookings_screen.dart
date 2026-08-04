import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/notifications/notification_router.dart';
import 'package:saloon_booking/core/notifications/notification_types.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/payments/presentation/providers/payment_provider.dart';
import 'package:saloon_booking/core/utils/booking_timeline_utils.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/animated_list_item.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/auto_refresh.dart';
import 'package:saloon_booking/shared/widgets/booking_card.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class CustomerBookingsScreen extends ConsumerStatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  ConsumerState<CustomerBookingsScreen> createState() =>
      _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends ConsumerState<CustomerBookingsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const _bookingsTabIndex = 2;

  Timer? _highlightTimer;
  late TabController _tabController;
  String? _highlightedBookingId;
  String? _pendingFocusId;
  bool _wantKeepAlive = true;

  @override
  bool get wantKeepAlive => _wantKeepAlive;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _focusBooking(
    String bookingId,
    List<BookingModel> active,
    List<BookingModel> past,
  ) {
    final inPast = past.any((b) => b.id == bookingId);
    final inActive = active.any((b) => b.id == bookingId);
    if (!inPast && !inActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (inPast && !inActive) {
        _tabController.animateTo(1);
      } else {
        _tabController.animateTo(0);
      }
      setState(() => _highlightedBookingId = bookingId);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _highlightedBookingId = null);
      });
    });
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
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(e))),
      );
    }
  }

  Widget _cancelButton(BuildContext context, WidgetRef ref, String bookingId) {
    return PremiumButton(
      label: 'Cancel',
      expand: false,
      size: PremiumButtonSize.small,
      variant: PremiumButtonVariant.ghost,
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancel booking?'),
            content: const Text(
              'Are you sure you want to cancel this booking request?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Cancel booking'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        await _runPaymentAction(
          context,
          () => ref.read(bookingActionsProvider.notifier).cancel(bookingId),
          'Booking cancelled',
        );
      },
    );
  }

  Widget _actionsBar(List<Widget> actions) {
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

  /// Group-level payment and review actions for a multi-service request.
  Widget? _groupTrailing(
    BuildContext context,
    WidgetRef ref,
    List<BookingModel> group,
  ) {
    final paymentLoading = ref.watch(paymentActionsProvider).isLoading;
    final representative = group.firstWhere(
      (b) => b.isPremium,
      orElse: () => group.first,
    );
    final rows = <Widget>[];

    if (_groupNeedsPremiumPayment(group)) {
      rows.add(
        PremiumCountdown(expiresAt: representative.premiumPayment?.expiresAt),
      );
      rows.add(
        _actionsBar([
          PremiumButton(
            label: 'Pay premium only',
            expand: false,
            size: PremiumButtonSize.small,
            loading: paymentLoading,
            onPressed: paymentLoading
                ? null
                : () => _runPaymentAction(
                    context,
                    () => ref
                        .read(paymentActionsProvider.notifier)
                        .payOnline(
                          booking: representative,
                          checkoutKind: 'PREMIUM_ONLY',
                        ),
                    'Premium payment successful',
                  ),
          ),
          if (representative.premiumAmount != null)
            PremiumButton(
              label:
                  'Pay full ₹${((representative.premiumAmount ?? 0) + _groupServiceTotal(group)).toStringAsFixed(0)}',
              expand: false,
              size: PremiumButtonSize.small,
              variant: PremiumButtonVariant.accent,
              loading: paymentLoading,
              onPressed: paymentLoading
                  ? null
                  : () => _runPaymentAction(
                      context,
                      () => ref
                          .read(paymentActionsProvider.notifier)
                          .payOnline(
                            booking: representative,
                            checkoutKind: 'COMBINED',
                          ),
                      'Payment successful',
                    ),
            ),
        ]),
      );
    } else if (_groupPremiumExpired(group)) {
      rows.add(
        Text(
          'Premium payment window expired',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (_groupCanChooseSalonPayment(group)) {
      rows.add(
        _actionsBar([
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
                        .payOnline(
                          booking: representative,
                          checkoutKind: 'SALON_FEE',
                        ),
                    'Payment successful',
                  ),
          ),
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
                        .selectPayAtShop(representative),
                    'Pay at shop selected',
                  ),
          ),
        ]),
      );
    }

    for (final booking in group) {
      if (customerCanReview(booking)) {
        final staffName = booking.staff?.name;
        rows.add(
          _actionsBar([
            PremiumButton(
              label: staffName != null && staffName.isNotEmpty
                  ? 'Rate salon · $staffName'
                  : 'Rate salon',
              expand: false,
              size: PremiumButtonSize.small,
              variant: PremiumButtonVariant.accent,
              onPressed: () => context.push(
                '${RoutePaths.customerBookings}/${booking.id}/review',
              ),
            ),
          ]),
        );
      } else if (booking.hasReview) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Salon reviewed',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.success),
            ),
          ),
        );
      }
    }

    if (group.any((b) => b.canCancel)) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _actionsBar([_cancelButton(context, ref, group.first.id)]),
        ),
      );
    }

    if (rows.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  bool _groupNeedsPremiumPayment(List<BookingModel> group) {
    final rep = group.firstWhere((b) => b.isPremium, orElse: () => group.first);
    return rep.needsPremiumPayment;
  }

  bool _groupPremiumExpired(List<BookingModel> group) {
    final rep = group.firstWhere((b) => b.isPremium, orElse: () => group.first);
    return rep.premiumPaymentExpired;
  }

  bool _groupCanChooseSalonPayment(List<BookingModel> group) {
    final rep = group.firstWhere((b) => b.isPremium, orElse: () => group.first);
    if (!rep.isAccepted) return false;
    if (rep.isPremium && rep.premiumPaymentStatus != 'PAID') return false;
    return !rep.salonFeePaid && !rep.salonFeePayAtShop;
  }

  double _groupServiceTotal(List<BookingModel> group) {
    return group.fold<double>(
      0,
      (sum, b) => sum + (b.service?.effectivePrice ?? 0),
    );
  }

  /// Groups bookings created from one request (same groupId) together,
  /// preserving order. Legacy rows without a groupId stand alone.
  List<List<BookingModel>> _groupByRequest(List<BookingModel> items) {
    final groups = <List<BookingModel>>[];
    final indexByKey = <String, int>{};
    for (final booking in items) {
      final key = booking.groupId ?? 'single:${booking.id}';
      final existing = indexByKey[key];
      if (existing == null) {
        indexByKey[key] = groups.length;
        groups.add([booking]);
      } else {
        groups[existing].add(booking);
      }
    }
    return groups;
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

    final groups = _groupByRequest(items);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        AppDecorations.scrollBottomPadding(context),
      ),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SectionHeader(
              title: isActiveTab ? 'Active appointments' : 'Past appointments',
              subtitle:
                  '${groups.length} booking${groups.length == 1 ? '' : 's'}',
            ),
          );
        }
        final group = groups[index - 1];
        // Prefer the premium row as the representative so the URGENT badge and
        // premium amount surface on the card.
        final representative = group.firstWhere(
          (b) => b.isPremium,
          orElse: () => group.first,
        );
        final serviceNames = group
            .map((b) => b.service?.serviceName)
            .whereType<String>()
            .toList();
        final highlighted = group.any((b) => b.id == _highlightedBookingId);
        return AnimatedListItem(
          index: index,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: highlighted
                  ? Border.all(color: context.appColors.accent, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: BookingCard(
              booking: representative,
              serviceNames: serviceNames,
              trailing: _groupTrailing(context, ref, group),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isBookingsTabActive =
        ref.watch(customerShellTabIndexProvider) == _bookingsTabIndex;
    if (_wantKeepAlive != isBookingsTabActive) {
      _wantKeepAlive = isBookingsTabActive;
      updateKeepAlive();
    }

    final bookings = ref.watch(myBookingsProvider);

    ref.listen(customerShellTabIndexProvider, (previous, next) {
      if (next == _bookingsTabIndex && previous != _bookingsTabIndex) {
        Future.microtask(() => ref.invalidate(myBookingsProvider));
      }
    });

    ref.listen(pendingNotificationTargetProvider, (previous, next) {
      if (next == null || next.bookingId.isEmpty) return;
      if (next.userRole == NotificationUserRoles.salonOwner) return;
      _pendingFocusId = next.bookingId;
      Future.microtask(
        () => ref.read(pendingNotificationTargetProvider.notifier).clear(),
      );
    });

    // Compute the active/past split once per build and reuse it for both the
    // tab labels and the tab views (previously it ran 4x per rebuild).
    final items = bookings.value;
    final active = items == null
        ? const <BookingModel>[]
        : customerActiveBookings(items);
    final past = items == null
        ? const <BookingModel>[]
        : customerPastBookings(items);

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'My bookings',
        subtitle: 'Active and past appointments',
      ),
      body: AutoRefresh(
        enabled: isBookingsTabActive,
        onRefresh: () async {
          ref.invalidate(myBookingsProvider);
          await ref.read(myBookingsProvider.future);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                elevated: false,
                child: TabBar(
                  controller: _tabController,
                  tabs: items == null
                      ? const [Tab(text: 'Active'), Tab(text: 'Past')]
                      : [
                          Tab(text: 'Active (${active.length})'),
                          Tab(text: 'Past (${past.length})'),
                        ],
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        context.appColors.accent.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
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
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          AppDecorations.scrollBottomPadding(context),
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

                    if (_pendingFocusId != null) {
                      final focusId = _pendingFocusId!;
                      _pendingFocusId = null;
                      _focusBooking(focusId, active, past);
                    }

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
      ),
    );
  }
}

/// Self-contained countdown that ticks once per second on its own, so it does
/// not force the whole bookings screen to rebuild every second. Pauses while idle.
class PremiumCountdown extends ConsumerStatefulWidget {
  const PremiumCountdown({super.key, required this.expiresAt});

  final DateTime? expiresAt;

  @override
  ConsumerState<PremiumCountdown> createState() => _PremiumCountdownState();
}

class _PremiumCountdownState extends ConsumerState<PremiumCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(PremiumCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _timer?.cancel();
      _timer = null;
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    if (widget.expiresAt == null || ref.read(userIdleProvider)) return;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || ref.read(userIdleProvider)) return;
      setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userIdleProvider, (previous, next) {
      if (next) {
        _stopTimer();
      } else {
        _startTimerIfNeeded();
        if (mounted) setState(() {});
      }
    });

    return Text(
      _remainingLabel(widget.expiresAt),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.warning,
        fontWeight: FontWeight.w700,
      ),
    );
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
}
