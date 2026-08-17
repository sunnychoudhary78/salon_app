import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/network/user_facing_error.dart';
import 'package:saloon_booking/core/providers/owner_approval_provider.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';
import 'package:saloon_booking/features/owner/presentation/providers/owner_dashboard_segment_provider.dart';
import 'package:saloon_booking/features/owner/presentation/providers/owner_setup_sheet_provider.dart';
import 'package:saloon_booking/features/owner/presentation/utils/owner_payout_status.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_header.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_layout.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_dashboard_skeleton.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_segment_selector.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/views/owner_growth_view.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/views/owner_money_view.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/views/owner_today_view.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/owner_account_alerts_card.dart';
import 'package:saloon_booking/shared/widgets/async_value_widget.dart';
import 'package:saloon_booking/shared/widgets/glass_bottom_sheet.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

/// Hosts the three dashboard segments. All content lives in
/// [OwnerTodayView], [OwnerMoneyView] and [OwnerGrowthView]; this screen only
/// owns the chrome, the segment switch and the one-shot setup sheet.
class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: ref.read(ownerDashboardSegmentProvider).index,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Map<String, String> _salonNames(OwnerDashboardV2Model dashboard) {
    final names = <String, String>{};
    for (final salon in dashboard.meta.availableSalons) {
      if (salon.salonName.isNotEmpty) {
        names[salon.salonId] = salon.salonName;
      }
    }
    for (final salon in dashboard.summary.bySalon) {
      names[salon.salonId] = salon.salonName;
    }
    for (final salon in dashboard.summary.profileCompleteness.salons) {
      names[salon.salonId] = salon.salonName;
    }
    return names;
  }

  Future<void> _refresh() async {
    await ref.read(authProvider.notifier).refreshProfile();
    await ref.read(hasApprovedSalonsProvider.notifier).refresh();
    ref.invalidate(ownerDashboardProvider);
    ref.invalidate(ownerPayoutAccountProvider);
  }

  void _selectSegment(OwnerDashboardSegment segment) {
    ref.read(ownerDashboardSegmentProvider.notifier).select(segment);
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      segment.index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
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
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Finish these items so you can accept bookings and get paid.',
              style: Theme.of(
                ctx,
              ).textTheme.bodyMedium?.copyWith(color: ctx.appColors.textMuted),
            ),
            const SizedBox(height: 16),
            OwnerAccountAlertsCard(profileCompleteness: profileCompleteness),
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
    final segment = ref.watch(ownerDashboardSegmentProvider);
    final application = auth?.salonApplication;
    final showApplicationStatus =
        application != null &&
        (application.isPending || application.isRejected);

    // When payout finishes loading after dashboard, retry the one-shot sheet.
    ref.listen(ownerPayoutAccountProvider, (previous, next) {
      final data = ref.read(ownerDashboardProvider).value;
      if (data == null) return;
      if (next.isLoading) return;
      _scheduleSetupSheetIfNeeded(data.summary.profileCompleteness);
    });

    // Scheduled here rather than inside a page builder: PageView can build
    // more than one page per frame and this must stay a single prompt.
    final loaded = dashboard.value;
    if (loaded != null &&
        !payoutAsync.isLoading &&
        !ref.read(ownerSetupSheetShownProvider)) {
      _scheduleSetupSheetIfNeeded(loaded.summary.profileCompleteness);
    }

    final scrollPadding = EdgeInsets.fromLTRB(
      kOwnerSegmentPadding.left,
      kOwnerSegmentPadding.top,
      kOwnerSegmentPadding.right,
      AppDecorations.scrollBottomPadding(context),
    );

    return Scaffold(
      appBar: OwnerDashboardHeader(
        greeting: _greeting(),
        ownerName: auth?.user.name ?? 'Owner',
        businessName: auth?.salonOwner?.businessName,
        meta:
            dashboard.value?.meta ??
            const OwnerDashboardMeta(
              salonIds: [],
              salonCount: 0,
              date: '',
              timezone: 'UTC',
              currency: 'INR',
            ),
        unreadFromDashboard:
            dashboard.value?.summary.notifications.unreadCount ?? 0,
        salonNames: dashboard.value == null
            ? const {}
            : _salonNames(dashboard.value!),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: OwnerSegmentSelector(
              selected: segment,
              onSelect: _selectSegment,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => ref
                  .read(ownerDashboardSegmentProvider.notifier)
                  .select(OwnerDashboardSegment.values[page]),
              children: [
                for (final value in OwnerDashboardSegment.values)
                  RefreshIndicator(
                    onRefresh: _refresh,
                    child: AsyncValueWidget(
                      value: dashboard,
                      loading: OwnerDashboardSkeleton(
                        segment: value,
                        scrollPadding: scrollPadding,
                      ),
                      error: (error, _) => ListView(
                        padding: scrollPadding,
                        children: [
                          const SizedBox(height: 40),
                          ErrorView(
                            message: userFacingErrorMessage(error),
                            onRetry: () =>
                                ref.invalidate(ownerDashboardProvider),
                          ),
                        ],
                      ),
                      data: (data) {
                        return switch (value) {
                          OwnerDashboardSegment.today => OwnerTodayView(
                            dashboard: data,
                            scrollPadding: scrollPadding,
                            application: showApplicationStatus
                                ? application
                                : null,
                          ),
                          OwnerDashboardSegment.money => OwnerMoneyView(
                            dashboard: data,
                            scrollPadding: scrollPadding,
                            payoutNeedsAction: ownerPayoutNeedsAction(
                              payoutAsync.value,
                            ),
                          ),
                          OwnerDashboardSegment.growth => OwnerGrowthView(
                            dashboard: data,
                            scrollPadding: scrollPadding,
                          ),
                        };
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
