import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// `OwnerShell` decides whether to show the bottom nav from
/// `currentConfiguration.last.matchedLocation`. These tests pin the go_router
/// behaviour that choice depends on: `RouteMatchList.uri` deliberately omits
/// imperatively pushed routes, and every nested owner screen uses
/// `context.push`, so the leaf match is the only reliable signal.
void main() {
  const branchRoots = {'/owner/dashboard', '/owner/salons'};
  late GoRouter router;

  bool showNav(GoRouterDelegate delegate) {
    final matches = delegate.currentConfiguration;
    if (matches.isEmpty) return false;
    return branchRoots.contains(matches.last.matchedLocation);
  }

  setUp(() {
    router = GoRouter(
      initialLocation: '/owner/dashboard',
      routes: [
        StatefulShellRoute.indexedStack(
          // Mirrors OwnerShell: the shell itself is not rebuilt by a push
          // inside a branch, so the nav bar listens to the router delegate.
          builder: (context, __, shell) {
            final delegate = GoRouter.of(context).routerDelegate;
            return AnimatedBuilder(
              animation: delegate,
              builder: (context, _) => Scaffold(
                body: shell,
                bottomNavigationBar: showNav(delegate)
                    ? const Text('NAV')
                    : null,
              ),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/owner/dashboard',
                  builder: (_, __) => const Scaffold(body: Text('dashboard')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/owner/salons',
                  builder: (_, __) => const Scaffold(body: Text('salons')),
                  routes: [
                    GoRoute(
                      path: ':salonId/edit',
                      // Stands in for the nested form screens, which supply
                      // their own bottom action bar.
                      builder: (_, __) => const Scaffold(
                        body: Text('edit salon'),
                        bottomNavigationBar: Text('ACTION BAR'),
                      ),
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

  String leafLocation() =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  testWidgets('leaf match tracks branch roots and pushed nested routes', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(leafLocation(), '/owner/dashboard');

    router.go('/owner/salons');
    await tester.pumpAndSettle();
    expect(leafLocation(), '/owner/salons');

    // A pushed nested screen must be visible in the leaf match, otherwise the
    // shell would keep the nav bar on top of the screen's own action bar.
    router.push('/owner/salons/abc/edit');
    await tester.pumpAndSettle();
    expect(leafLocation(), '/owner/salons/abc/edit');

    // `uri` is the value that does not see the push; guarding against a
    // regression that would make it look usable here.
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/owner/salons',
    );

    router.pop();
    await tester.pumpAndSettle();
    expect(leafLocation(), '/owner/salons');
  });

  testWidgets('nav bar shows on branch roots and hides on a pushed screen', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('NAV'), findsOneWidget);

    router.go('/owner/salons');
    await tester.pumpAndSettle();
    expect(find.text('NAV'), findsOneWidget);

    router.push('/owner/salons/abc/edit');
    await tester.pumpAndSettle();
    expect(find.text('ACTION BAR'), findsOneWidget);
    expect(find.text('NAV'), findsNothing);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('NAV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
