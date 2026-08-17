import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/theme/app_theme.dart';
import 'package:saloon_booking/features/customer/data/services/customer_service.dart';
import 'package:saloon_booking/features/customer/presentation/screens/write_review_screen.dart';

void main() {
  testWidgets('star row does not overflow at 360px width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [myBookingsProvider.overrideWith((ref) async => [])],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WriteReviewScreen(bookingId: 'booking-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Write review'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
