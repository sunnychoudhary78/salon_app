import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saloon_booking/core/routing/navigation_utils.dart';

/// Mirrors owner/customer shell back handling after a profile save: a GoRouter
/// refresh (auth update) plus `go` to the profile tab must not pop the shell.
void main() {
  for (final fixture in _fixtures) {
    group(fixture.name, () {
      late GoRouter router;
      late _Refresh refresh;

      setUp(() {
        refresh = _Refresh();
        router = GoRouter(
          initialLocation: fixture.home,
          refreshListenable: refresh,
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, __, shell) {
                return Scaffold(
                  body: shell,
                  bottomNavigationBar: TextButton(
                    onPressed: () => _handleBack(context, fixture, shell),
                    child: const Text('BACK'),
                  ),
                );
              },
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: fixture.home,
                      builder: (_, __) => Text(fixture.homeLabel),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: fixture.profile,
                      builder: (_, __) => Text(fixture.profileLabel),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (_, __) => Text(fixture.editLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      });

      tearDown(() => router.dispose());

      testWidgets(
        'save-then-back from profile goes home instead of popping the shell',
        (tester) async {
          await tester.pumpWidget(MaterialApp.router(routerConfig: router));
          await tester.pumpAndSettle();

          router.go(fixture.profile);
          await tester.pumpAndSettle();
          expect(find.text(fixture.profileLabel), findsOneWidget);

          router.push(fixture.edit);
          await tester.pumpAndSettle();
          expect(find.text(fixture.editLabel), findsOneWidget);
          expect(routerLeafLocation(router), fixture.edit);

          // Profile save updates auth → GoRouter refreshListenable.
          refresh.ping();
          await tester.pumpAndSettle();

          // Save lands on the profile tab root (go, not a blind pop).
          router.go(fixture.profile);
          await tester.pumpAndSettle();
          expect(find.text(fixture.profileLabel), findsOneWidget);
          expect(routerLeafLocation(router), fixture.profile);

          final action = resolveShellBack(
            leaf: routerLeafLocation(router),
            branchRoots: fixture.branchRoots,
            canPop: router.canPop(),
            atHomeTab: false,
          );
          expect(action, ShellBackAction.goHome);

          await tester.tap(find.text('BACK'));
          await tester.pumpAndSettle();

          expect(find.text(fixture.homeLabel), findsOneWidget);
          expect(router.routerDelegate.currentConfiguration.isEmpty, isFalse);
          expect(routerLeafLocation(router), fixture.home);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('back on the edit screen still pops to profile', (
        tester,
      ) async {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        router.go(fixture.profile);
        await tester.pumpAndSettle();
        router.push(fixture.edit);
        await tester.pumpAndSettle();

        expect(
          resolveShellBack(
            leaf: routerLeafLocation(router),
            branchRoots: fixture.branchRoots,
            canPop: router.canPop(),
            atHomeTab: false,
          ),
          ShellBackAction.popNested,
        );

        await tester.tap(find.text('BACK'));
        await tester.pumpAndSettle();

        expect(find.text(fixture.profileLabel), findsOneWidget);
        expect(routerLeafLocation(router), fixture.profile);
      });
    });
  }
}

class _Fixture {
  const _Fixture({
    required this.name,
    required this.home,
    required this.profile,
    required this.edit,
    required this.homeLabel,
    required this.profileLabel,
    required this.editLabel,
    required this.branchRoots,
    required this.homeIndex,
  });

  final String name;
  final String home;
  final String profile;
  final String edit;
  final String homeLabel;
  final String profileLabel;
  final String editLabel;
  final Set<String> branchRoots;
  final int homeIndex;
}

const _fixtures = [
  _Fixture(
    name: 'owner',
    home: '/owner/dashboard',
    profile: '/owner/profile',
    edit: '/owner/profile/edit',
    homeLabel: 'dashboard',
    profileLabel: 'profile',
    editLabel: 'edit profile',
    branchRoots: {'/owner/dashboard', '/owner/profile'},
    homeIndex: 0,
  ),
  _Fixture(
    name: 'customer',
    home: '/customer/home',
    profile: '/customer/profile',
    edit: '/customer/profile/edit',
    homeLabel: 'home',
    profileLabel: 'profile',
    editLabel: 'edit profile',
    branchRoots: {'/customer/home', '/customer/profile'},
    homeIndex: 0,
  ),
];

void _handleBack(
  BuildContext context,
  _Fixture fixture,
  StatefulNavigationShell shell,
) {
  final router = GoRouter.of(context);
  final action = resolveShellBack(
    leaf: routerLeafLocation(router),
    branchRoots: fixture.branchRoots,
    canPop: router.canPop(),
    atHomeTab: shell.currentIndex == fixture.homeIndex,
  );
  switch (action) {
    case ShellBackAction.popNested:
      router.pop();
    case ShellBackAction.goHome:
      shell.goBranch(fixture.homeIndex);
    case ShellBackAction.doubleBackExit:
      break;
  }
}

class _Refresh extends ChangeNotifier {
  void ping() => notifyListeners();
}
