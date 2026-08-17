import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/shared/widgets/booking_card.dart';
import 'package:saloon_booking/shared/widgets/booking_when_badge.dart';
import 'package:saloon_booking/shared/widgets/status_badge.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Color? _textColor(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style?.color;
}

void main() {
  testWidgets('status badge uses brand colors, not traffic-light green/red', (
    tester,
  ) async {
    await _pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(status: 'PENDING'),
          StatusBadge(status: 'ACCEPTED'),
          StatusBadge(status: 'COMPLETED'),
          StatusBadge(status: 'CANCELLED'),
          StatusBadge(status: 'REJECTED'),
          StatusBadge(status: 'ACTIVE'),
          StatusBadge(status: 'VERIFIED'),
        ],
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);

    final colors = AppTheme.dark.extension<AppThemeExtension>()!;
    expect(_textColor(tester, 'Pending'), AppColors.warning);
    expect(_textColor(tester, 'Accepted'), colors.primary);
    expect(_textColor(tester, 'Active'), colors.primary);
    expect(_textColor(tester, 'Verified'), colors.primary);
    expect(_textColor(tester, 'Completed'), colors.textSecondary);
    expect(_textColor(tester, 'Cancelled'), colors.textSecondary);
    expect(_textColor(tester, 'Rejected'), colors.textSecondary);
    expect(_textColor(tester, 'Accepted'), isNot(AppColors.success));
    expect(_textColor(tester, 'Rejected'), isNot(AppColors.error));
  });

  testWidgets('upcoming when-badge uses primary, not success green', (
    tester,
  ) async {
    final tomorrow = DateTime.now().add(const Duration(days: 2));
    final date =
        '${tomorrow.year.toString().padLeft(4, '0')}-'
        '${tomorrow.month.toString().padLeft(2, '0')}-'
        '${tomorrow.day.toString().padLeft(2, '0')}';

    await _pump(tester, BookingWhenBadge(date: date, time: '14:00:00'));

    expect(find.text('Upcoming'), findsOneWidget);
    final colors = AppTheme.dark.extension<AppThemeExtension>()!;
    expect(_textColor(tester, 'Upcoming'), colors.primary);
    expect(_textColor(tester, 'Upcoming'), isNot(AppColors.success));
  });

  testWidgets('booking cards lay out every status without overflow', (
    tester,
  ) async {
    const statuses = [
      'PENDING',
      'ACCEPTED',
      'COMPLETED',
      'CANCELLED',
      'REJECTED',
    ];

    await _pump(
      tester,
      ListView(
        children: [
          for (final status in statuses)
            BookingCard(
              booking: BookingModel(
                id: status,
                bookingStatus: status,
                bookingDate: '2026-08-20',
                bookingTime: '14:30:00',
                rejectionReason: status == 'REJECTED' ? 'Fully booked' : null,
                salon: const BookingSalonRef(
                  id: 's1',
                  salonName: 'Glow Studio',
                ),
                service: const BookingServiceRef(
                  serviceName: 'Haircut',
                  durationMinutes: 30,
                ),
              ),
            ),
        ],
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Declined: Fully booked'), findsOneWidget);
  });
}
