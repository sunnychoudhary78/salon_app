import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/app.dart';
import 'package:saloon_booking/shared/widgets/app_logo.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SalonApp()));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(AppLogo), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    // Let storage timeout futures started during app bootstrap settle.
    await tester.pump(const Duration(seconds: 6));
  });
}
