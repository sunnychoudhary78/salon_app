import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SalonApp()));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('CATCHY'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
