import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/crash/crash_reporting.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_provider.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/notifications/notification_router.dart';
import 'package:saloon_booking/core/notifications/notification_types.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/utils/booking_timeline_utils.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/core/utils/form_validators.dart';
import 'package:saloon_booking/features/owner/data/models/owner_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/providers/owner_booking_focus_provider.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/extra_cash_dialog.dart';
import 'package:saloon_booking/shared/widgets/animated_list_item.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/auto_refresh.dart';
import 'package:saloon_booking/shared/widgets/booking_when_badge.dart';
import 'package:saloon_booking/shared/widgets/empty_state.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/premium_countdown.dart';
import 'package:saloon_booking/shared/widgets/premium_dialog.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';
import 'package:saloon_booking/shared/widgets/status_badge.dart';
import 'package:saloon_booking/shared/widgets/staff_avatar.dart';

class OwnerBookingsScreen extends ConsumerStatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  ConsumerState<OwnerBookingsScreen> createState() =>
      _OwnerBookingsScreenState();
}

enum _OwnerBookingAction { accept, reject, complete, confirmCash }

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const _bookingsTabIndex = 2;

  late TabController _tabController;
  String? _processingBookingId;
  _OwnerBookingAction? _processingAction;
  List<OwnerBookingModel>? _localBookings;
  String? _highlightedBookingId;
  String? _pendingFocusId;
  bool _pendingOpenDetail = false;
  Timer? _highlightTimer;
  bool _wantKeepAlive = true;
  bool _todayFilterActive = false;
  Future<void>? _refreshFuture;
  DateTime? _lastRefreshAt;

  @override
  bool get wantKeepAlive => _wantKeepAlive;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(ownerBookingsTodayFilterProvider)) {
        setState(() => _todayFilterActive = true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _highlightTimer?.cancel();
    final filterNotifier = ref.read(ownerBookingsTodayFilterProvider.notifier);
    Future.microtask(filterNotifier.clear);
    super.dispose();
  }

  List<OwnerBookingModel> _applyTodayFilter(List<OwnerBookingModel> items) {
    if (!_todayFilterActive) return items;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return items.where((b) => b.bookingDate.startsWith(today)).toList();
  }

  void _clearTodayFilter() {
    setState(() => _todayFilterActive = false);
    ref.read(ownerBookingsTodayFilterProvider.notifier).clear();
  }

  Future<void> _refreshBookings({bool force = false}) {
    // Don't clobber optimistic UI while an accept/reject/complete is running.
    if (_processingBookingId != null) return Future.value();
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;
    final lastRefreshAt = _lastRefreshAt;
    if (!force &&
        lastRefreshAt != null &&
        DateTime.now().difference(lastRefreshAt) <
            const Duration(seconds: 10)) {
      return Future.value();
    }

    final future = CrashReporting.measureAsync(
      'owner_bookings_refresh',
      () async {
        ref.invalidate(ownerAllBookingsProvider);
        final fresh = await ref.read(ownerAllBookingsProvider.future);
        if (mounted) setState(() => _localBookings = fresh);
      },
    );
    _refreshFuture = future;
    return future.whenComplete(() {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
        _lastRefreshAt = DateTime.now();
      }
    });
  }

  void _focusBooking(
    String bookingId,
    List<OwnerBookingModel> items, {
    bool openDetail = false,
  }) {
    final inActive = ownerActiveBookings(items).any((b) => b.id == bookingId);
    final inPast = ownerPastBookings(items).any((b) => b.id == bookingId);
    if (!inActive && !inPast) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tabController.animateTo(inActive ? 0 : 1);
      setState(() => _highlightedBookingId = bookingId);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _highlightedBookingId = null);
      });

      if (openDetail) {
        final groups = _groupByRequest(items);
        for (final group in groups) {
          if (group.any((b) => b.id == bookingId)) {
            unawaited(_showBookingDetail(group));
            break;
          }
        }
      }
    });
  }

  /// Groups bookings that came from one multi-service request (same groupId)
  /// into a single entry, preserving the incoming order. Legacy rows without a
  /// groupId each become their own group.
  List<List<OwnerBookingModel>> _groupByRequest(List<OwnerBookingModel> items) {
    final groups = <List<OwnerBookingModel>>[];
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

  bool _isBookingProcessing(String bookingId) =>
      _processingBookingId == bookingId;

  bool _isProcessing(String bookingId, _OwnerBookingAction action) =>
      _processingBookingId == bookingId && _processingAction == action;

  List<OwnerBookingModel>? _providerBookings() {
    return ref
        .read(ownerAllBookingsProvider)
        .maybeWhen(data: (items) => items, orElse: () => null);
  }

  OwnerBookingModel _displayBooking(OwnerBookingModel booking) {
    final items = _localBookings;
    if (items == null) return booking;
    for (final item in items) {
      if (item.id == booking.id) return item;
    }
    return booking;
  }

  void _applyBookingUpdate(OwnerBookingModel updated) {
    final current = _localBookings ?? _providerBookings();
    if (current == null) return;

    final next = [
      for (final booking in current)
        booking.id == updated.id ? updated : booking,
    ];
    final replaced = current.any((booking) => booking.id == updated.id);
    if (!replaced) next.insert(0, updated);

    setState(() => _localBookings = next);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatBookingDateTime(String date, String time) {
    final parsed = DateTime.tryParse(date);
    final dateLabel = parsed != null ? DateFormat.yMMMd().format(parsed) : date;
    if (time.isEmpty) return dateLabel;
    return '$dateLabel · $time';
  }

  String _errorMessage(Object error) => userFacingErrorMessage(error);

  Future<bool> _runBookingAction({
    required String bookingId,
    required _OwnerBookingAction action,
    required Future<OwnerBookingModel> Function() request,
    required String successMessage,
    BuildContext? closeContext,
    VoidCallback? onStateChanged,
  }) async {
    if (_processingBookingId != null) return false;

    final current = _localBookings ?? _providerBookings();
    setState(() {
      _processingBookingId = bookingId;
      _processingAction = action;
      if (_localBookings == null && current != null) {
        _localBookings = current;
      }
    });
    onStateChanged?.call();

    try {
      final updated = await request();
      if (!mounted) return false;
      _applyBookingUpdate(updated);
      if (closeContext != null && closeContext.mounted) {
        Navigator.pop(closeContext);
      }
      _showSnackBar(successMessage);
      return true;
    } catch (error) {
      _showSnackBar(_errorMessage(error));
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _processingBookingId = null;
          _processingAction = null;
        });
        onStateChanged?.call();
      }
    }
  }

  Future<bool> _acceptBooking(
    String bookingId, {
    BuildContext? closeContext,
    VoidCallback? onStateChanged,
  }) {
    return _runBookingAction(
      bookingId: bookingId,
      action: _OwnerBookingAction.accept,
      request: () => ref.read(ownerBookingActionsProvider).accept(bookingId),
      successMessage: 'Booking accepted',
      closeContext: closeContext,
      onStateChanged: onStateChanged,
    );
  }

  Future<bool> _completeBooking(
    OwnerBookingModel booking, {
    BuildContext? closeContext,
    VoidCallback? onStateChanged,
  }) async {
    double? extraAmount;
    extraAmount = await showExtraCashDialog(
      context: context,
      bookedAmount: booking.salonFeeAmount ?? 0,
      title: booking.requiresCashConfirmation
          ? 'Complete & confirm cash'
          : 'Mark completed',
      confirmLabel: 'Complete',
      alreadyPaidOnline: !booking.requiresCashConfirmation,
    );
    if (extraAmount == null) return false;
    if (!mounted) return false;
    if (closeContext != null && !closeContext.mounted) return false;
    return _runBookingAction(
      bookingId: booking.id,
      action: _OwnerBookingAction.complete,
      request: () => ref
          .read(ownerBookingActionsProvider)
          .complete(booking.id, extraAmount: extraAmount),
      successMessage: 'Booking completed',
      closeContext: closeContext,
      onStateChanged: onStateChanged,
    );
  }

  Future<bool> _confirmCashPayment(
    List<OwnerBookingModel> group, {
    BuildContext? closeContext,
    VoidCallback? onStateChanged,
  }) async {
    if (_processingBookingId != null) return false;
    final booking = group.first;
    final groupId = booking.groupId ?? booking.id;

    final extraAmount = await showExtraCashDialog(
      context: context,
      bookedAmount: booking.salonFeeAmount ?? 0,
      title: 'Confirm cash received',
      confirmLabel: 'Confirm cash',
    );
    if (extraAmount == null) return false;
    if (!mounted) return false;
    if (closeContext != null && !closeContext.mounted) return false;

    setState(() {
      _processingBookingId = booking.id;
      _processingAction = _OwnerBookingAction.confirmCash;
    });
    onStateChanged?.call();

    try {
      await ref
          .read(ownerBookingActionsProvider)
          .confirmCashPayment(groupId, extraAmount: extraAmount);
      if (!mounted) return false;
      await _refreshBookings();
      if (closeContext != null && closeContext.mounted) {
        Navigator.pop(closeContext);
      }
      _showSnackBar('Cash payment confirmed');
      return true;
    } catch (error) {
      _showSnackBar(_errorMessage(error));
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _processingBookingId = null;
          _processingAction = null;
        });
        onStateChanged?.call();
      }
    }
  }

  Future<void> _showBookingDetail(List<OwnerBookingModel> group) async {
    final serviceNames = group
        .map((b) => b.serviceName)
        .whereType<String>()
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final displayedGroup = [
            for (final item in group) _displayBooking(item),
          ];
          final currentBooking = displayedGroup.first;
          final isUrgent = ownerGroupIsPremium(displayedGroup);
          final premiumAmount = ownerGroupPremiumAmount(displayedGroup);
          final premiumBooking = ownerGroupPremium(displayedGroup);
          final status = currentBooking.bookingStatus.toUpperCase();
          final processingThis = _isBookingProcessing(currentBooking.id);
          void notifySheet() {
            if (ctx.mounted) setSheetState(() {});
          }

          return Padding(
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
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ctx.appColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    StaffAvatar(
                      name: currentBooking.customer?.name ?? 'C',
                      imageUrl: currentBooking.customer?.profileImage,
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentBooking.customer?.name ?? 'Customer',
                            style: Theme.of(ctx).textTheme.titleLarge,
                          ),
                          if (currentBooking.bookingNumber != null)
                            Text(
                              '#${currentBooking.bookingNumber}',
                              style: Theme.of(ctx).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.appColors.textMuted,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    StatusBadge(status: currentBooking.bookingStatus),
                  ],
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.spa_outlined,
                        label: serviceNames.length > 1 ? 'Services' : 'Service',
                        value: serviceNames.isEmpty
                            ? (currentBooking.serviceName ?? '—')
                            : serviceNames.join(', '),
                      ),
                      if (currentBooking.salonName != null)
                        _DetailRow(
                          icon: Icons.store_outlined,
                          label: 'Salon',
                          value: currentBooking.salonName!,
                        ),
                      if (currentBooking.staffName != null)
                        _DetailRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Preferred staff',
                          value: currentBooking.staffName!,
                        ),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date & time',
                        value: _formatBookingDateTime(
                          currentBooking.bookingDate,
                          currentBooking.bookingTime,
                        ),
                      ),
                      if (currentBooking.customer?.phone != null)
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: currentBooking.customer!.phone!,
                        ),
                    ],
                  ),
                ),
                if (isUrgent) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.appColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Urgent booking'
                      '${premiumAmount != null ? ' · ${formatMoney(premiumAmount)} premium' : ''}',
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: context.appColors.accent,
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
                          loading: _isProcessing(
                            currentBooking.id,
                            _OwnerBookingAction.accept,
                          ),
                          loadingLabel: 'Accepting',
                          onPressed: processingThis
                              ? null
                              : () => _acceptBooking(
                                  currentBooking.id,
                                  closeContext: ctx,
                                  onStateChanged: notifySheet,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PremiumButton(
                          label: 'Reject',
                          variant: PremiumButtonVariant.ghost,
                          loading: _isProcessing(
                            currentBooking.id,
                            _OwnerBookingAction.reject,
                          ),
                          loadingLabel: 'Rejecting',
                          onPressed: processingThis
                              ? null
                              : () => _reject(
                                  currentBooking.id,
                                  closeContext: ctx,
                                  onStateChanged: notifySheet,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (status == 'ACCEPTED') ...[
                  const SizedBox(height: 20),
                  if (premiumBooking.needsPremiumPayment ||
                      premiumBooking.premiumPaymentExpired) ...[
                    PremiumCountdown(
                      expiresAt: premiumBooking.premiumPaymentDueAt,
                      unpaidLabel: 'Waiting for customer to pay premium',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!currentBooking.canComplete)
                    Text(
                      currentBooking.paymentWaitingMessage,
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: context.appColors.textMuted,
                      ),
                    )
                  else ...[
                    if (currentBooking.requiresCashConfirmation) ...[
                      PremiumButton(
                        label: 'Confirm cash received',
                        variant: PremiumButtonVariant.ghost,
                        loading: _isProcessing(
                          currentBooking.id,
                          _OwnerBookingAction.confirmCash,
                        ),
                        loadingLabel: 'Confirming',
                        onPressed: processingThis
                            ? null
                            : () => _confirmCashPayment(
                                group,
                                closeContext: ctx,
                                onStateChanged: notifySheet,
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    PremiumButton(
                      label: currentBooking.requiresCashConfirmation
                          ? 'Complete & confirm cash'
                          : 'Mark completed',
                      loading: _isProcessing(
                        currentBooking.id,
                        _OwnerBookingAction.complete,
                      ),
                      loadingLabel: 'Completing',
                      onPressed: processingThis
                          ? null
                          : () => _completeBooking(
                              currentBooking,
                              closeContext: ctx,
                              onStateChanged: notifySheet,
                            ),
                    ),
                  ],
                ],
                if (status == 'COMPLETED' &&
                    currentBooking.requiresCashConfirmation) ...[
                  const SizedBox(height: 20),
                  PremiumButton(
                    label: 'Confirm cash received',
                    loading: _isProcessing(
                      currentBooking.id,
                      _OwnerBookingAction.confirmCash,
                    ),
                    loadingLabel: 'Confirming',
                    onPressed: processingThis
                        ? null
                        : () => _confirmCashPayment(
                            group,
                            closeContext: ctx,
                            onStateChanged: notifySheet,
                          ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(List<OwnerBookingModel> group) {
    final displayedGroup = [for (final item in group) _displayBooking(item)];
    final booking = displayedGroup.first;
    final isUrgent = ownerGroupIsPremium(displayedGroup);
    final premiumBooking = ownerGroupPremium(displayedGroup);
    final status = booking.bookingStatus.toUpperCase();
    final processingThis = _isBookingProcessing(booking.id);
    final highlighted = group.any((b) => b.id == _highlightedBookingId);
    final serviceNames = group
        .map((b) => b.serviceName)
        .whereType<String>()
        .toList();
    final servicesLabel = serviceNames.isEmpty
        ? 'Service'
        : serviceNames.join(', ');
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted ? context.appColors.accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: GlassCard(
        onTap: processingThis ? null : () => _showBookingDetail(group),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StaffAvatar(
                  name: booking.customer?.name ?? 'C',
                  imageUrl: booking.customer?.profileImage,
                  size: 36,
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
                        servicesLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textMuted,
                        ),
                      ),
                      if (serviceNames.length > 1)
                        Text(
                          '${serviceNames.length} services in this request',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: context.appColors.accent),
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
                      color: context.appColors.accent.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatBookingDateTime(
                        booking.bookingDate,
                        booking.bookingTime,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                BookingWhenBadge(
                  date: booking.bookingDate,
                  time: booking.bookingTime,
                  compact: true,
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.appColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'URGENT',
                      style: TextStyle(
                        color: context.appColors.accent,
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
                  color: context.appColors.accent,
                ),
              ),
            ],
            if (booking.staffName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Staff: ${booking.staffName}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.appColors.textMuted,
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
                      loading: _isProcessing(
                        booking.id,
                        _OwnerBookingAction.accept,
                      ),
                      loadingLabel: 'Accepting',
                      onPressed: processingThis
                          ? null
                          : () => _acceptBooking(booking.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PremiumButton(
                      label: 'Reject',
                      size: PremiumButtonSize.small,
                      variant: PremiumButtonVariant.ghost,
                      loading: _isProcessing(
                        booking.id,
                        _OwnerBookingAction.reject,
                      ),
                      loadingLabel: 'Rejecting',
                      onPressed: processingThis
                          ? null
                          : () => _reject(booking.id),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'ACCEPTED' &&
                (premiumBooking.needsPremiumPayment ||
                    premiumBooking.premiumPaymentExpired))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: PremiumCountdown(
                  expiresAt: premiumBooking.premiumPaymentDueAt,
                  unpaidLabel: 'Waiting for customer to pay premium',
                ),
              ),
            if (status == 'ACCEPTED' && !booking.canComplete)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  booking.paymentWaitingMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appColors.textMuted,
                  ),
                ),
              ),
            if (status == 'ACCEPTED' && booking.canComplete)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: PremiumButton(
                  label: booking.requiresCashConfirmation
                      ? 'Complete & confirm cash'
                      : 'Mark completed',
                  size: PremiumButtonSize.small,
                  loading: _isProcessing(
                    booking.id,
                    _OwnerBookingAction.complete,
                  ),
                  loadingLabel: 'Completing',
                  onPressed: processingThis
                      ? null
                      : () => _completeBooking(booking),
                ),
              ),
            if (status == 'COMPLETED' && booking.requiresCashConfirmation)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: PremiumButton(
                  label: 'Confirm cash received',
                  size: PremiumButtonSize.small,
                  loading: _isProcessing(
                    booking.id,
                    _OwnerBookingAction.confirmCash,
                  ),
                  loadingLabel: 'Confirming',
                  onPressed: processingThis
                      ? null
                      : () => _confirmCashPayment(group),
                ),
              ),
          ],
        ),
      ),
    );

    if (highlighted &&
        !animationsDisabled(context) &&
        !ref.watch(userIdleProvider)) {
      card = card
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            duration: 1200.ms,
            color: context.appColors.accent.withValues(alpha: 0.12),
          );
    }
    return card;
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

    final pending = _groupByRequest(ownerPendingBookings(items));
    final upcoming = _groupByRequest(ownerUpcomingAcceptedBookings(items));

    final entries = <_BookingListEntry>[];
    if (pending.isNotEmpty) {
      entries.add(
        _BookingListEntry.header(
          'Needs your response',
          '${pending.length} pending request${pending.length == 1 ? '' : 's'}',
        ),
      );
      entries.addAll(pending.map(_BookingListEntry.card));
    }
    if (upcoming.isNotEmpty) {
      entries.add(
        _BookingListEntry.header(
          'Upcoming appointments',
          '${upcoming.length} confirmed booking${upcoming.length == 1 ? '' : 's'}',
          topGap: pending.isNotEmpty,
        ),
      );
      entries.addAll(upcoming.map(_BookingListEntry.card));
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        AppDecorations.scrollBottomPadding(context),
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry.isHeader) {
          return AnimatedListItem(
            index: index,
            child: Padding(
              padding: EdgeInsets.only(top: entry.topGap ? 20 : 0, bottom: 12),
              child: SectionHeader(
                title: entry.title!,
                subtitle: entry.subtitle,
              ),
            ),
          );
        }
        return AnimatedListItem(
          index: index,
          child: _buildBookingCard(entry.group!),
        );
      },
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

    final groups = _groupByRequest(items);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        AppDecorations.scrollBottomPadding(context),
      ),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return AnimatedListItem(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionHeader(
                title: 'Past appointments',
                subtitle:
                    '${groups.length} booking${groups.length == 1 ? '' : 's'}',
              ),
            ),
          );
        }
        return AnimatedListItem(
          index: index,
          child: _buildBookingCard(groups[index - 1]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isBookingsTabActive =
        ref.watch(ownerShellTabIndexProvider) == _bookingsTabIndex;
    if (_wantKeepAlive != isBookingsTabActive) {
      _wantKeepAlive = isBookingsTabActive;
      updateKeepAlive();
    }

    final bookings = ref.watch(ownerAllBookingsProvider);

    ref.listen(ownerAllBookingsProvider, (previous, next) {
      next.whenData((items) {
        if (!mounted || _processingBookingId != null) return;
        setState(() => _localBookings = items);
      });
    });

    ref.listen(ownerShellTabIndexProvider, (previous, next) {
      if (next == _bookingsTabIndex && previous != _bookingsTabIndex) {
        Future.microtask(() => unawaited(_refreshBookings()));
      }
    });

    ref.listen(pendingNotificationTargetProvider, (previous, next) {
      if (next == null || next.bookingId.isEmpty) return;
      if (next.userRole != NotificationUserRoles.salonOwner) return;
      _pendingFocusId = next.bookingId;
      _pendingOpenDetail = false;
      Future.microtask(
        () => ref.read(pendingNotificationTargetProvider.notifier).clear(),
      );
    });

    ref.listen(ownerBookingFocusProvider, (previous, next) {
      if (next == null || next.bookingId.isEmpty) return;
      _pendingFocusId = next.bookingId;
      _pendingOpenDetail = next.openDetail;
      if (_todayFilterActive) {
        setState(() => _todayFilterActive = false);
      }
      Future.microtask(
        () => ref.read(ownerBookingFocusProvider.notifier).clear(),
      );
    });

    final visibleBookings = bookings.maybeWhen(
      data: (items) => _applyTodayFilter(items),
      loading: () =>
          _localBookings == null ? null : _applyTodayFilter(_localBookings!),
      error: (error, stackTrace) =>
          _localBookings == null ? null : _applyTodayFilter(_localBookings!),
      orElse: () =>
          _localBookings == null ? null : _applyTodayFilter(_localBookings!),
    );

    if (_pendingFocusId != null) {
      final allItems = bookings.maybeWhen(
        data: (items) => items,
        orElse: () => _localBookings,
      );
      if (allItems != null) {
        final focusId = _pendingFocusId!;
        final openDetail = _pendingOpenDetail;
        _pendingFocusId = null;
        _pendingOpenDetail = false;
        _focusBooking(focusId, allItems, openDetail: openDetail);
      }
    }
    // Compute the active/past split once per build and reuse it for tab labels
    // and tab views (previously it ran up to 4x per rebuild).
    final active = visibleBookings == null
        ? const <OwnerBookingModel>[]
        : ownerActiveBookings(visibleBookings);
    final past = visibleBookings == null
        ? const <OwnerBookingModel>[]
        : ownerPastBookings(visibleBookings);

    final tabs = visibleBookings == null
        ? const [Tab(text: 'Active'), Tab(text: 'Past')]
        : [
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'Past (${past.length})'),
          ];

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Bookings',
        subtitle: _todayFilterActive
            ? "Today's appointments"
            : 'Active and past appointments',
        actions: _todayFilterActive
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: const Text('Today'),
                    avatar: const Icon(Icons.close, size: 16),
                    onPressed: _clearTodayFilter,
                  ),
                ),
              ]
            : null,
      ),
      body: GradientBackground(
        child: AutoRefresh(
          enabled: isBookingsTabActive,
          onRefresh: _refreshBookings,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: GlassCard(
                  padding: const EdgeInsets.all(4),
                  elevated: true,
                  radius: 18,
                  child: TabBar(
                    controller: _tabController,
                    tabs: tabs,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                    unselectedLabelStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: context.appColors.accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: context.appColors.accent.withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    labelColor: context.appColors.onAccent,
                    unselectedLabelColor: context.appColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refreshBookings(force: true),
                  child: visibleBookings == null
                      ? AsyncValueWidget(
                          value: bookings,
                          data: (items) {
                            return TabBarView(
                              controller: _tabController,
                              children: [
                                _buildActiveList(ownerActiveBookings(items)),
                                _buildPastList(ownerPastBookings(items)),
                              ],
                            );
                          },
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildActiveList(active),
                            _buildPastList(past),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reject(
    String bookingId, {
    BuildContext? closeContext,
    VoidCallback? onStateChanged,
  }) async {
    if (_processingBookingId != null) return;

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => PremiumDialog(
        title: 'Reject booking',
        subtitle: 'Optionally provide a reason for the customer.',
        content: PremiumTextField(
          controller: reasonController,
          label: 'Reason (optional)',
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(kNotesMaxLength)],
          validator: validateOptionalNotes,
        ),
        confirmLabel: 'Reject',
        cancelLabel: 'Cancel',
        confirmVariant: PremiumButtonVariant.accent,
        onConfirm: () => Navigator.pop(ctx, reasonController.text),
        onCancel: () => Navigator.pop(ctx),
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    if (closeContext != null && !closeContext.mounted) return;
    await _runBookingAction(
      bookingId: bookingId,
      action: _OwnerBookingAction.reject,
      request: () => ref
          .read(ownerBookingActionsProvider)
          .reject(bookingId, reason: reason.isEmpty ? null : reason),
      successMessage: 'Booking rejected',
      closeContext: closeContext,
      onStateChanged: onStateChanged,
    );
  }
}

/// Lightweight descriptor so the active list (which has multiple sections) can
/// render lazily through a single [ListView.builder].
class _BookingListEntry {
  const _BookingListEntry._({
    required this.isHeader,
    this.title,
    this.subtitle,
    this.topGap = false,
    this.group,
  });

  factory _BookingListEntry.header(
    String title,
    String subtitle, {
    bool topGap = false,
  }) {
    return _BookingListEntry._(
      isHeader: true,
      title: title,
      subtitle: subtitle,
      topGap: topGap,
    );
  }

  factory _BookingListEntry.card(List<OwnerBookingModel> group) {
    return _BookingListEntry._(isHeader: false, group: group);
  }

  final bool isHeader;
  final String? title;
  final String? subtitle;
  final bool topGap;
  final List<OwnerBookingModel>? group;
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: context.appColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.appColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
