import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/shared/widgets/auto_refresh.dart';

void main() {
  testWidgets('does not overlap refresh callbacks', (tester) async {
    final firstRefresh = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: AutoRefresh(
          interval: const Duration(milliseconds: 10),
          minimumGap: Duration.zero,
          refreshOnResume: false,
          onRefresh: () {
            calls++;
            return firstRefresh.future;
          },
          child: const SizedBox(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 1);

    firstRefresh.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(calls, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
