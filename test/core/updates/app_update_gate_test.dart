import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_booking/core/theme/app_theme.dart';
import 'package:saloon_booking/core/ui/root_scaffold_messenger.dart';
import 'package:saloon_booking/core/updates/app_update_gate.dart';
import 'package:saloon_booking/core/updates/app_update_policy.dart';
import 'package:saloon_booking/core/updates/play_store_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('update prompt policy', () {
    final now = DateTime(2026, 8, 13, 19);

    test('is not snoozed when never dismissed', () {
      expect(isUpdateSnoozed(null, now), isFalse);
    });

    test('is snoozed within 24 hours', () {
      final snoozedAt = now.subtract(const Duration(hours: 3));
      expect(isUpdateSnoozed(snoozedAt.millisecondsSinceEpoch, now), isTrue);
    });

    test('is not snoozed after 24 hours', () {
      final snoozedAt = now.subtract(const Duration(hours: 25));
      expect(isUpdateSnoozed(snoozedAt.millisecondsSinceEpoch, now), isFalse);
    });

    test('prompts when an update is available and not snoozed', () {
      expect(
        shouldPromptForAvailableUpdate(snoozed: false, updateAvailable: true),
        isTrue,
      );
    });

    test('skips when snoozed even if an update is available', () {
      expect(
        shouldPromptForAvailableUpdate(snoozed: true, updateAvailable: true),
        isFalse,
      );
    });

    test('skips when no update is available', () {
      expect(
        shouldPromptForAvailableUpdate(snoozed: false, updateAvailable: false),
        isFalse,
      );
    });
  });

  group('AppUpdateGate', () {
    late _FakePlayStoreUpdateService fake;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fake = _FakePlayStoreUpdateService(
        checkResult: const PlayStoreUpdateCheck(
          updateAvailable: true,
          flexibleAllowed: true,
          alreadyDownloaded: false,
        ),
      );
    });

    Future<void> pumpGate(
      WidgetTester tester, {
      String location = '/customer/home',
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          theme: AppTheme.light,
          home: AppUpdateGate(
            currentLocation: () => location,
            service: fake,
            isSupportedPlatform: () => true,
            child: const Scaffold(body: Text('home')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets('shows the update dialog when Play has a newer version', (
      tester,
    ) async {
      await pumpGate(tester);
      expect(find.text('New version available'), findsOneWidget);
      expect(find.text('Update now'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('skips the dialog while snoozed', (tester) async {
      SharedPreferences.setMockInitialValues({
        updatePromptSnoozeKey: DateTime.now().millisecondsSinceEpoch,
      });
      await pumpGate(tester);
      expect(find.text('New version available'), findsNothing);
    });

    testWidgets('does not prompt on the splash route', (tester) async {
      await pumpGate(tester, location: '/splash');
      expect(find.text('New version available'), findsNothing);
    });

    testWidgets('Later stores a snooze timestamp', (tester) async {
      await pumpGate(tester);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.text('New version available'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(updatePromptSnoozeKey), isNotNull);
    });
  });
}

class _FakePlayStoreUpdateService implements PlayStoreUpdateService {
  _FakePlayStoreUpdateService({required this.checkResult});

  PlayStoreUpdateCheck checkResult;

  @override
  Future<PlayStoreUpdateCheck> check() async => checkResult;

  @override
  Future<void> completeFlexibleUpdate() async {}

  @override
  Future<bool> openStoreListing() async => true;

  @override
  Future<FlexibleUpdateStartResult> startFlexibleUpdate() async =>
      FlexibleUpdateStartResult.downloaded;
}
