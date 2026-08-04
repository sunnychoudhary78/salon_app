import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/theme/app_theme.dart';
import 'package:saloon_booking/features/customer/data/models/salon_model.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/booking/booking_service_selection_card.dart';
import 'package:saloon_booking/shared/widgets/service_artwork.dart';

void main() {
  const service = ServiceModel(
    id: 'service-1',
    serviceName: 'Haircut',
    price: 600,
    discountPrice: 450,
    durationMinutes: 45,
    description: 'A tailored cut and finish',
  );

  Widget buildCard({
    bool selected = false,
    VoidCallback? onTap,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: BookingServiceSelectionCard(
              service: service,
              selected: selected,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows artwork, service details, duration, and discount price', (
    tester,
  ) async {
    await tester.pumpWidget(buildCard());

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Haircut'), findsOneWidget);
    expect(find.text('A tailored cut and finish'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('₹600'), findsOneWidget);
    expect(find.text('₹450'), findsOneWidget);
  });

  testWidgets('toggles through the full-card tap target and shows selection', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      buildCard(
        selected: true,
        onTap: () => tapped = true,
        theme: AppTheme.dark,
      ),
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.tap(find.byType(BookingServiceSelectionCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('keeps the transparent service artwork on white in both themes', (
    tester,
  ) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(buildCard(theme: theme));

      final artworkContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(ServiceArtwork),
          matching: find.byType(Container),
        ),
      );
      final decoration = artworkContainer.decoration! as BoxDecoration;
      expect(decoration.color, Colors.white);
    }
  });
}
