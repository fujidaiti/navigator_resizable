import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigator_resizable/src/navigator_event_observer.dart';

/// Regression tests for the crash that occurs when the page stack is changed
/// faster than the route transitions can settle.
///
/// `NavigatorEventObserverState._didChangeNext` treats "my next route became
/// null" as "the route above me was popped, so I am the top route again".
/// That inference does not hold for a route that was itself already popped and
/// is still running its exit transition: while it is animating out, a newer
/// route can be pushed above it and popped again, which resets its next route
/// to null even though it will never become current again.
/// `_didPopNextInternal` then trips its `assert(route.isCurrent)`.
///
/// Because the assertion escapes from `Route.didChangeNext`, which the
/// navigator dispatches while `_debugLocked` is set (and without a `finally`),
/// the navigator is left permanently locked and every later frame throws
/// `!_debugLocked`.
void main() {
  group('Declarative navigator API', () {
    ({
      Widget testWidget,
      ValueSetter<String> setLocation,
      ValueGetter<NavigatorEventObserverState> getObserver,
    })
    boilerplate() {
      final pageA = _testPage('a');
      final pageB = _testPage('b');
      final pageC = _testPage('c');

      var location = '/a';
      late VoidCallback invokeSetState;
      final observerKey = GlobalKey<NavigatorEventObserverState>();

      final testWidget = MaterialApp(
        home: NavigatorEventObserver(
          key: observerKey,
          child: StatefulBuilder(
            builder: (_, setState) {
              invokeSetState = () => setState(() {});
              return Navigator(
                onDidRemovePage: (_) {},
                pages: switch (location) {
                  '/a' => [pageA],
                  '/a/b' => [pageA, pageB],
                  '/a/b/c' => [pageA, pageB, pageC],
                  _ => throw StateError('Unknown location: $location'),
                },
              );
            },
          ),
        ),
      );

      return (
        testWidget: testWidget,
        setLocation: (String newLocation) {
          location = newLocation;
          invokeSetState();
        },
        getObserver: () => observerKey.currentState!,
      );
    }

    testWidgets(
      'Toggling the page stack faster than the transitions settle',
      (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);

        // Each hop is applied while the previous transition is still running.
        // The 3rd hop pushes a new 'c' route on top of the 'c' route that the
        // 2nd hop is still popping, and the 4th hop pops that new route again,
        // which resets the still-popping 'c' route's next route to null.
        const hops = ['/a/b/c', '/a', '/a/b/c', '/a'];
        const steps = [100, 16, 16, 16];
        for (final (index, hop) in hops.indexed) {
          env.setLocation(hop);
          await tester.pump();
          await tester.pump(Duration(milliseconds: steps[index]));
          expect(
            tester.takeException(),
            isNull,
            reason: 'An error occurred while navigating to $hop',
          );
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Page:a'), findsOneWidget);
        expect(env.getObserver().lastSettledRoute, isA<Route<dynamic>>());

        // The navigator must still be usable afterwards.
        env.setLocation('/a/b');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Page:b'), findsOneWidget);
      },
    );
  });

  group('Imperative navigator API', () {
    ({
      Widget testWidget,
      GlobalKey<NavigatorState> navigatorKey,
      ValueGetter<NavigatorEventObserverState> getObserver,
    })
    boilerplate() {
      final navigatorKey = GlobalKey<NavigatorState>();
      final observerKey = GlobalKey<NavigatorEventObserverState>();
      final testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: 'a',
        onGenerateRoute: (settings) => _TestPageRoute(settings: settings),
        builder: (_, navigator) => NavigatorEventObserver(
          key: observerKey,
          child: navigator!,
        ),
      );

      return (
        testWidget: testWidget,
        navigatorKey: navigatorKey,
        getObserver: () => observerKey.currentState!,
      );
    }

    testWidgets(
      'Pushing and popping faster than the transitions settle',
      (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);
        final navigator = env.navigatorKey.currentState!;

        // 'b' is popped while it is still entering, then 'c' is pushed on top
        // of the still-popping 'b' and popped again, which resets 'b's next
        // route to null even though 'b' will never become current again.
        const steps = [100, 16, 16, 16];
        final operations = <VoidCallback>[
          () => navigator.pushNamed('b'),
          navigator.pop,
          () => navigator.pushNamed('c'),
          navigator.pop,
        ];
        for (final (index, operation) in operations.indexed) {
          operation();
          await tester.pump();
          await tester.pump(Duration(milliseconds: steps[index]));
          expect(
            tester.takeException(),
            isNull,
            reason: 'An error occurred at operation #$index',
          );
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Page:a'), findsOneWidget);
        expect(env.getObserver().lastSettledRoute, isA<Route<dynamic>>());

        // The navigator must still be usable afterwards.
        navigator.pushNamed('b');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Page:b'), findsOneWidget);
      },
    );
  });
}

const _transitionDuration = Duration(milliseconds: 300);

_TestPage _testPage(String name) =>
    _TestPage(key: ValueKey(name), name: name, child: _TestScaffold(name));

class _TestPage extends MaterialPage<dynamic> {
  const _TestPage({super.key, super.name, required super.child});

  @override
  Route<dynamic> createRoute(BuildContext context) =>
      _TestPageRoute(settings: this);
}

class _TestPageRoute extends PageRoute<dynamic>
    with ObservableRouteMixin<dynamic>, MaterialRouteTransitionMixin<dynamic> {
  _TestPageRoute({required RouteSettings super.settings});

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Widget buildContent(BuildContext context) => switch (settings) {
    final _TestPage page => page.child,
    final other => _TestScaffold(other.name!),
  };
}

class _TestScaffold extends StatelessWidget {
  const _TestScaffold(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Page:$name')));
  }
}
