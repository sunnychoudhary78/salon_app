import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/lifecycle/user_activity_provider.dart';

void main() {
  testWidgets('enters idle state and returns on activity', (tester) async {
    final container = ProviderContainer();

    expect(container.read(userIdleProvider), isFalse);

    await tester.pump(userIdleTimeout);
    expect(container.read(userIdleProvider), isTrue);

    container.read(userIdleProvider.notifier).recordActivity();
    expect(container.read(userIdleProvider), isFalse);

    container.dispose();
    await tester.pump();
  });
}
