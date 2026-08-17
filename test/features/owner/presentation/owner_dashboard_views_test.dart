import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/theme/app_theme.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/features/owner/presentation/providers/owner_dashboard_segment_provider.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/owner_segment_selector.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/views/owner_growth_view.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/views/owner_money_view.dart';
import 'package:saloon_booking/features/owner/presentation/widgets/dashboard/views/owner_today_view.dart';

/// Fully populated payload so every conditional section renders.
Map<String, dynamic> _busyDashboardJson() => {
  'meta': {
    'salon_ids': ['s1', 's2'],
    'salon_count': 2,
    'available_salons': [
      {'salon_id': 's1', 'salon_name': 'Glow Studio Koramangala'},
      {'salon_id': 's2', 'salon_name': 'Glow Studio Indiranagar'},
    ],
    'date': '2026-08-11',
    'timezone': 'Asia/Kolkata',
    'currency': 'INR',
    'period': {'key': '30d', 'label': 'Last 30 days', 'granularity': 'day'},
  },
  'summary': {
    'bookings': {
      'pending': 4,
      'upcoming': 12,
      'today': 7,
      'completed_in_period': 132,
    },
    'revenue': {
      'today_gross': 4820.5,
      'period_gross': 148320.75,
      'period': {'key': '30d', 'label': 'Last 30 days'},
    },
    'earnings': {
      'pending': 3200.0,
      'in_batch': 1500.0,
      'pending_total': 4700.0,
      'settled': 98000.0,
      'collected_at_salon': 21000.0,
      'platform_fee_owed': 640.0,
    },
    'reputation': {'average_rating': 4.6, 'review_count': 218},
    'premium_bookings_count': 9,
    'utilization': {
      'percent': 78.4,
      'occupied_slots': 31,
      'total_slots': 40,
      'available_slots': 9,
      'status': 'BUSY',
    },
    'profile_completeness': {'average_percent': 100, 'incomplete_count': 0},
    'notifications': {'unread_count': 3},
    'by_salon': [
      {
        'salon_id': 's1',
        'salon_name': 'Glow Studio Koramangala',
        'today_bookings': 5,
        'utilization_percent': 82.0,
      },
      {
        'salon_id': 's2',
        'salon_name': 'Glow Studio Indiranagar',
        'today_bookings': 2,
        'utilization_percent': 64.5,
      },
    ],
  },
  'attention': {
    'total_count': 2,
    'sections': [
      {
        'type': 'cash_confirmations_pending',
        'count': 1,
        'severity': 'HIGH',
        'items': [
          {
            'booking_id': 'b1',
            'booking_number': 'BK-1001',
            'customer_name': 'Ananya Krishnamurthy',
            'salon_name': 'Glow Studio Koramangala',
            'booking_time': '14:30:00',
            'amount': 1299.0,
          },
        ],
      },
      {
        'type': 'premium_unpaid',
        'count': 1,
        'severity': 'MEDIUM',
        'items': [
          {
            'booking_id': 'b2',
            'booking_number': 'BK-1002',
            'customer_name': 'Rajeshwari Balasubramanian',
            'salon_name': 'Glow Studio Indiranagar',
            'booking_date': '2026-08-11',
            'booking_time': '16:00:00',
            'is_premium': true,
          },
        ],
      },
    ],
  },
  'schedule': {
    'appointments': [
      {
        'visit_id': 'v1',
        'booking_date': '2026-08-11',
        'booking_time': '14:30:00',
        'booking_status': 'ACCEPTED',
        'salon': {'id': 's1', 'salon_name': 'Glow Studio Koramangala'},
        'customer': {
          'id': 'c1',
          'name': 'Ananya Krishnamurthy',
          'phone': '+919876543210',
        },
        'services': [
          {
            'booking_id': 'b1',
            'booking_number': 'BK-1001',
            'service_name': 'Keratin Treatment',
            'booking_type': 'PREMIUM',
            'premium_amount': 350.0,
            'premium_payment_status': 'PENDING',
          },
          {
            'booking_id': 'b1b',
            'service_name': 'Hair Spa',
            'booking_type': 'NORMAL',
          },
        ],
        'payment_summary': {
          'requires_cash_confirmation': true,
          'method': 'PAY_AT_SHOP',
        },
      },
      {
        'visit_id': 'v2',
        'booking_date': '2026-08-11',
        'booking_time': '16:00:00',
        'booking_status': 'PENDING',
        'salon': {'id': 's2', 'salon_name': 'Glow Studio Indiranagar'},
        'customer': {'id': 'c2', 'name': 'Rajeshwari Balasubramanian'},
        'services': [
          {'booking_id': 'b2', 'service_name': 'Bridal Makeup'},
        ],
      },
    ],
    'pagination': {'limit': 10, 'has_more': false},
  },
  'performance': {
    'period': {
      'to': '2026-08-11',
      'key': '30d',
      'label': 'Last 30 days',
      'granularity': 'day',
      'days': 30,
    },
    'booking_trend': [
      {'date': '2026-08-05', 'count': 6},
      {'date': '2026-08-06', 'count': 11},
      {'date': '2026-08-07', 'count': 4},
      {'date': '2026-08-08', 'count': 14},
    ],
    'revenue_trend': [
      {'date': '2026-08-05', 'amount': 4200.0},
      {'date': '2026-08-06', 'amount': 9100.5},
      {'date': '2026-08-07', 'amount': 2800.0},
      {'date': '2026-08-08', 'amount': 12750.25},
    ],
    'top_services': [
      {
        'service_id': 'sv1',
        'service_name': 'Hair Smoothening',
        'booking_count': 42,
        'revenue': 84000.0,
        'rank': 1,
      },
      {
        'service_id': 'sv2',
        'service_name': 'Keratin Treatment',
        'booking_count': 28,
        'revenue': 56000.0,
        'rank': 2,
      },
    ],
    'customers': {
      'new': 64,
      'returning': 96,
      'total_active': 160,
      'new_percent': 40.0,
    },
  },
};

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  const padding = EdgeInsets.fromLTRB(16, 12, 16, 24);

  group('owner dashboard segments', () {
    late OwnerDashboardV2Model busy;
    late OwnerDashboardV2Model empty;

    setUp(() {
      busy = OwnerDashboardV2Model.fromJson(_busyDashboardJson());
      empty = OwnerDashboardV2Model.fromJson(const {});
    });

    testWidgets('today view lays out a busy salon day', (tester) async {
      await _pump(
        tester,
        OwnerTodayView(dashboard: busy, scrollPadding: padding),
      );

      expect(tester.takeException(), isNull);
      // Next-up hero owns the first appointment.
      expect(find.text('NEXT UP'), findsOneWidget);
      expect(find.text('Ananya Krishnamurthy'), findsWidgets);
      // Operational counters come from the hero's metric group.
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
      expect(find.textContaining('Needs attention'), findsOneWidget);
    });

    testWidgets('today view handles an empty dashboard', (tester) async {
      await _pump(
        tester,
        OwnerTodayView(dashboard: empty, scrollPadding: padding),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Nothing left today'), findsOneWidget);
      // No attention items means the action center must not take up space.
      expect(find.textContaining('Needs attention'), findsNothing);
    });

    testWidgets('money view shows revenue and payout warning', (tester) async {
      await _pump(
        tester,
        OwnerMoneyView(
          dashboard: busy,
          scrollPadding: padding,
          payoutNeedsAction: true,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Last 30 days revenue'), findsWidgets);
      expect(
        find.text('Set up your payout account to withdraw'),
        findsOneWidget,
      );

      // Shortcuts sit below the fold.
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();

      expect(find.text('Payout account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('money view hides the payout warning when set up', (
      tester,
    ) async {
      await _pump(
        tester,
        OwnerMoneyView(
          dashboard: busy,
          scrollPadding: padding,
          payoutNeedsAction: false,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Set up your payout account to withdraw'), findsNothing);
    });

    testWidgets('growth view surfaces top services, customers and salons', (
      tester,
    ) async {
      await _pump(
        tester,
        OwnerGrowthView(dashboard: busy, scrollPadding: padding),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('4.6'), findsOneWidget);
      expect(find.text('218 reviews'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);

      // Scroll to reach the lower sections of the view.
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(find.text('Top services'), findsOneWidget);
      expect(find.text('Hair Smoothening'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('growth view handles an empty dashboard', (tester) async {
      await _pump(
        tester,
        OwnerGrowthView(dashboard: empty, scrollPadding: padding),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('No data for this period yet'), findsOneWidget);
      // Single-salon owners should not see the per-salon breakdown.
      expect(find.text('By salon'), findsNothing);
    });

    testWidgets('views fit a narrow phone without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pump(
        tester,
        OwnerTodayView(dashboard: busy, scrollPadding: padding),
      );
      expect(tester.takeException(), isNull);

      await _pump(
        tester,
        OwnerGrowthView(dashboard: busy, scrollPadding: padding),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('segment selector reports the tapped segment', (tester) async {
    final tapped = <OwnerDashboardSegment>[];

    await _pump(
      tester,
      OwnerSegmentSelector(
        selected: OwnerDashboardSegment.today,
        onSelect: tapped.add,
      ),
    );

    await tester.tap(find.text('Growth'));
    await tester.pump();

    expect(tapped, [OwnerDashboardSegment.growth]);

    // Re-tapping the active segment should not fire.
    await tester.tap(find.text('Today'));
    await tester.pump();

    expect(tapped, [OwnerDashboardSegment.growth]);
  });

  group('owner dashboard salon catalog', () {
    test('scoped salon_count still exposes the full picker catalog', () {
      final dashboard = OwnerDashboardV2Model.fromJson({
        'meta': {
          'salon_ids': ['s1'],
          'salon_count': 1,
          'scoped_salon_id': 's1',
          'available_salons': [
            {'salon_id': 's1', 'salon_name': 'Glow Studio Koramangala'},
            {'salon_id': 's2', 'salon_name': 'Glow Studio Indiranagar'},
          ],
          'date': '2026-08-13',
          'timezone': 'Asia/Kolkata',
          'currency': 'INR',
        },
      });

      expect(dashboard.meta.salonCount, 1);
      expect(dashboard.meta.canSwitchSalons, isTrue);
      expect(dashboard.meta.pickerSalons.map((s) => s.salonId).toList(), [
        's1',
        's2',
      ]);
    });

    test('falls back to salonCount when available_salons is omitted', () {
      final multi = OwnerDashboardV2Model.fromJson({
        'meta': {
          'salon_ids': ['s1', 's2'],
          'salon_count': 2,
          'date': '2026-08-13',
          'timezone': 'Asia/Kolkata',
          'currency': 'INR',
        },
      });
      final single = OwnerDashboardV2Model.fromJson({
        'meta': {
          'salon_ids': ['s1'],
          'salon_count': 1,
          'date': '2026-08-13',
          'timezone': 'Asia/Kolkata',
          'currency': 'INR',
        },
      });

      expect(multi.meta.canSwitchSalons, isTrue);
      expect(multi.meta.pickerSalons.map((s) => s.salonId).toList(), [
        's1',
        's2',
      ]);
      expect(single.meta.canSwitchSalons, isFalse);
    });
  });
}
