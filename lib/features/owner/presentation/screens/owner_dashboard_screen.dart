import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/providers/owner_setup_sheet_provider.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_payout_status.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_action_center.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_header.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_quick_actions.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_skeleton.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_finance_card.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_next_appointment_card.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_performance_charts.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_premium_strip.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_secondary_kpi_carousel.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_snapshot_kpi_row.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_today_schedule_list.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/owner_account_alerts_card.dart';
import 'package:saloon_booking/features/profile/presentation/widgets/salon_application_status_card.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_bottom_sheet.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Map<String, String> _salonNames(OwnerDashboardV2Model dashboard) {
    final names = <String, String>{};
    for (final salon in dashboard.summary.bySalon) {
      names[salon.salonId] = salon.salonName;
    }
    for (final salon in dashboard.summary.profileCompleteness.salons) {
      names[salon.salonId] = salon.salonName;
    }
    return names;
  }

  String _revenuePeriodLabel(OwnerDashboardRevenueSummary revenue) {
    final label = revenue.period?.label;
    if (label == null || label.isEmpty) return "Period revenue";
    return '$label revenue';
  }

  Future<void> _maybeShowSetupSheet(
    OwnerDashboardProfileCompleteness profileCompleteness,
  ) async {
    if (!mounted) return;
    if (ref.read(ownerSetupSheetShownProvider)) return;

    final payoutAsync = ref.read(ownerPayoutAccountProvider);
    if (payoutAsync.isLoading) return;

    final payoutNeedsAction = ownerPayoutNeedsAction(payoutAsync.value);
    final showProfile = profileCompleteness.averagePercent < 100;
    if (!payoutNeedsAction && !showProfile) {
      ref.read(ownerSetupSheetShownProvider.notifier).markShown();
      return;
    }

    ref.read(ownerSetupSheetShownProvider.notifier).markShown();

    await showGlassBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          28 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Complete your setup',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Finish these items so you can accept bookings and get paid.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: ctx.appColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            OwnerAccountAlertsCard(
              profileCompleteness: profileCompleteness,
            ),
            const SizedBox(height: 16),
            PremiumButton(
              label: 'Not now',
              variant: PremiumButtonVariant.ghost,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleSetupSheetIfNeeded(
    OwnerDashboardProfileCompleteness profileCompleteness,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowSetupSheet(profileCompleteness);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).value;
    final dashboard = ref.watch(ownerDashboardProvider);
    final payoutAsync = ref.watch(ownerPayoutAccountProvider);
    final application = auth?.salonApplication;
    final showApplicationStatus =
        application != null &&
        (application.isPending || application.isRejected);
    final businessName = auth?.salonOwner?.businessName;

    // When payout finishes loading after dashboard, retry the one-shot sheet.
    ref.listen(ownerPayoutAccountProvider, (previous, next) {
      final data = ref.read(ownerDashboardProvider).value;
      if (data == null) return;
      if (next.isLoading) return;
      _scheduleSetupSheetIfNeeded(data.summary.profileCompleteness);
    });

    return Scaffold(
      appBar: dashboard.maybeWhen(
        data: (data) => OwnerDashboardHeader(
          greeting: _greeting(),
          ownerName: auth?.user.name ?? 'Owner',
          businessName: businessName,
          meta: data.meta,
          unreadFromDashboard: data.summary.notifications.unreadCount,
          salonNames: _salonNames(data),
        ),
        orElse: () => OwnerDashboardHeader(
          greeting: _greeting(),
          ownerName: auth?.user.name ?? 'Owner',
          businessName: businessName,
          meta: const OwnerDashboardMeta(
            salonIds: [],
            salonCount: 0,
            date: '',
            timezone: 'UTC',
            currency: 'INR',
          ),
          unreadFromDashboard: 0,
          salonNames: const {},
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(ownerBookingsTodayFilterProvider.notifier).enable();
          context.go(RoutePaths.ownerBookings);
        },
        backgroundColor: context.appColors.accent,
        foregroundColor: context.appColors.onAccent,
        elevation: 4,
        icon: const Icon(Icons.calendar_today_rounded),
        label: const Text(
          'Today',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshProfile();
          await ref.read(hasApprovedSalonsProvider.notifier).refresh();
          ref.invalidate(ownerDashboardProvider);
          ref.invalidate(ownerPayoutAccountProvider);
        },
        child: AsyncValueWidget(
          value: dashboard,
          loading: const OwnerDashboardSkeleton(),
          data: (data) {
            if (!ref.read(ownerSetupSheetShownProvider) &&
                !payoutAsync.isLoading) {
              _scheduleSetupSheetIfNeeded(data.summary.profileCompleteness);
            }

            final appointments = data.schedule.appointments;
            final nextAppointment =
                appointments.isNotEmpty ? appointments.first : null;
            final baseIndex = showApplicationStatus ? 1 : 0;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                AppDecorations.scrollBottomPadding(context),
              ),
              children: [
                if (showApplicationStatus) ...[
                  AnimatedEntrance(
                    child: SalonApplicationStatusCard(application: application),
                  ),
                  const SizedBox(height: 18),
                ],
                AnimatedEntrance(
                  index: baseIndex,
                  child: OwnerActionCenter(attention: data.attention),
                ),
                const SizedBox(height: 18),
                AnimatedEntrance(
                  index: baseIndex + 1,
                  child: OwnerNextAppointmentCard(appointment: nextAppointment),
                ),
                const SizedBox(height: 12),
                AnimatedEntrance(
                  index: baseIndex + 2,
                  child: OwnerTodayScheduleList(
                    appointments: appointments,
                    skipFirst: nextAppointment != null,
                    maxItems: 5,
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedEntrance(
                  index: baseIndex + 3,
                  child: OwnerSnapshotKpiRow(
                    bookings: data.summary.bookings,
                    utilization: data.summary.utilization,
                    premiumBookingsCount: data.summary.premiumBookingsCount,
                    reputation: data.summary.reputation,
                    showCompletedInPeriod:
                        data.summary.revenue.period?.key != '7d',
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedEntrance(
                  index: baseIndex + 4,
                  child: OwnerFinanceCard(
                    revenue: data.summary.revenue,
                    earnings: data.summary.earnings,
                    currency: data.meta.currency,
                    compact: true,
                    payoutNeedsAction: false,
                    periodLabel: _revenuePeriodLabel(data.summary.revenue),
                  ),
                ),
                if (data.summary.premiumBookingsCount > 0 ||
                    data.premiumTodayCount > 0 ||
                    data.premiumUnpaidCount > 0) ...[
                  const SizedBox(height: 12),
                  AnimatedEntrance(
                    index: baseIndex + 5,
                    child: OwnerPremiumStrip(
                      activeCount: data.summary.premiumBookingsCount,
                      todayCount: data.premiumTodayCount,
                      unpaidCount: data.premiumUnpaidCount,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                AnimatedEntrance(
                  index: baseIndex + 6,
                  child: OwnerSecondaryKpiCarousel(
                    bookings: data.summary.bookings,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  index: baseIndex + 7,
                  child: OwnerPerformanceCharts(
                    performance: data.performance,
                    currency: data.meta.currency,
                  ),
                ),
                const SizedBox(height: 22),
                const AnimatedEntrance(
                  index: 10,
                  child: SectionHeader(
                    title: 'Quick actions',
                    subtitle: 'Jump to key areas',
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedEntrance(
                  index: 11,
                  child: OwnerDashboardQuickActions(
                    pendingBookings: data.summary.bookings.pending,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
