import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/routing/route_paths.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_action_center.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_header.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_quick_actions.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_skeleton.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_finance_card.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_next_appointment_card.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_performance_charts.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_premium_strip.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/owner_account_alerts_card.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_payout_status.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_secondary_kpi_carousel.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_snapshot_kpi_row.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_today_schedule_list.dart';
import 'package:saloon_booking/features/profile/presentation/widgets/salon_application_status_card.dart';
import 'package:saloon_booking/shared/widgets/animated_entrance.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    final dashboard = ref.watch(ownerDashboardProvider);
    final payoutAccount = ref.watch(ownerPayoutAccountProvider).value;
    final payoutNeedsAction = ownerPayoutNeedsAction(payoutAccount);
    final application = auth?.salonApplication;
    final showApplicationStatus = application != null &&
        (application.isPending || application.isRejected);
    final businessName = auth?.salonOwner?.businessName;

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
        icon: const Icon(Icons.calendar_today_rounded),
        label: const Text('Today'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshProfile();
          await ref.read(hasApprovedSalonsProvider.notifier).refresh();
          ref.invalidate(ownerDashboardProvider);
        },
        child: AsyncValueWidget(
          value: dashboard,
          loading: const OwnerDashboardSkeleton(),
          data: (data) {
            final nextAppointment = data.schedule.appointments.isNotEmpty
                ? data.schedule.appointments.first
                : null;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                AppDecorations.scrollBottomPadding(context),
              ),
              children: [
                if (showApplicationStatus) ...[
                  AnimatedEntrance(
                    child: SalonApplicationStatusCard(application: application),
                  ),
                  const SizedBox(height: 16),
                ],
                AnimatedEntrance(
                  index: showApplicationStatus ? 1 : 0,
                  child: OwnerAccountAlertsCard(
                    profileCompleteness: data.summary.profileCompleteness,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  index: showApplicationStatus ? 2 : 1,
                  child: OwnerActionCenter(attention: data.attention),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  index: showApplicationStatus ? 3 : 2,
                  child: OwnerSnapshotKpiRow(
                    bookings: data.summary.bookings,
                    utilization: data.summary.utilization,
                    premiumBookingsCount: data.summary.premiumBookingsCount,
                    reputation: data.summary.reputation,
                    showCompletedInPeriod:
                        data.summary.revenue.period?.key != '7d',
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedEntrance(
                  index: showApplicationStatus ? 4 : 3,
                  child: OwnerFinanceCard(
                    revenue: data.summary.revenue,
                    earnings: data.summary.earnings,
                    currency: data.meta.currency,
                    compact: true,
                    payoutNeedsAction: payoutNeedsAction,
                    periodLabel: _revenuePeriodLabel(data.summary.revenue),
                  ),
                ),
                if (data.summary.premiumBookingsCount > 0 ||
                    data.premiumTodayCount > 0 ||
                    data.premiumUnpaidCount > 0) ...[
                  const SizedBox(height: 12),
                  AnimatedEntrance(
                    index: showApplicationStatus ? 5 : 4,
                    child: OwnerPremiumStrip(
                      activeCount: data.summary.premiumBookingsCount,
                      todayCount: data.premiumTodayCount,
                      unpaidCount: data.premiumUnpaidCount,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AnimatedEntrance(
                  index: showApplicationStatus ? 6 : 5,
                  child: OwnerNextAppointmentCard(appointment: nextAppointment),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  index: showApplicationStatus ? 7 : 6,
                  child: OwnerTodayScheduleList(
                    appointments: data.schedule.appointments,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedEntrance(
                  index: showApplicationStatus ? 8 : 7,
                  child: OwnerSecondaryKpiCarousel(
                    bookings: data.summary.bookings,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedEntrance(
                  index: showApplicationStatus ? 9 : 8,
                  child: OwnerPerformanceCharts(
                    performance: data.performance,
                    currency: data.meta.currency,
                  ),
                ),
                const SizedBox(height: 20),
                const AnimatedEntrance(
                  index: 10,
                  child: SectionHeader(
                    title: 'Quick actions',
                    subtitle: 'Jump to key areas',
                  ),
                ),
                const SizedBox(height: 12),
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
