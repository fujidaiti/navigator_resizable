import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resizable_navigator/src/route_transition_observer.dart';
import 'package:resizable_navigator/src/route_transition_status.dart';

import 'src/matchers.dart';

void main() {
  late RouteTransitionObserver transitionObserver;
  late List<RouteTransitionStatus> transitionStatusHistory;
  late List<double> transitionProgressHistory;

  setUp(() {
    transitionObserver = RouteTransitionObserver();
    transitionStatusHistory = [];
    transitionProgressHistory = [];
  });

  // Use the returned callback to stop tracking the transition progress.
  VoidCallback startTrackingTransitionProgress(Animation<double> progress) {
    transitionProgressHistory = [];
    void listener() => transitionProgressHistory.add(progress.value);
    progress.addListener(listener);
    return () => progress.removeListener(listener);
  }

  group('Transition event capturing test with imperative navigator API', () {
    late Widget testWidget;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      testWidget = MaterialApp(
        navigatorObservers: [transitionObserver],
        navigatorKey: navigatorKey,
        initialRoute: '/a',
        routes: {
          '/a': (_) => const Scaffold(),
          '/b': (_) => const Scaffold(),
        },
        builder: (context, navigator) {
          return _TestRouteTransitionObserverWidget(
            onTransitionStatusChanged: transitionStatusHistory.add,
            transitionObserver: transitionObserver,
            child: navigator!,
          );
        },
      );
    });

    testWidgets('On initial build', (tester) async {
      await tester.pumpWidget(testWidget);
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: '/a'),
        ),
      ]);
    });

    testWidgets('When pushing a route', (tester) async {
      await tester.pumpWidget(testWidget);
      transitionStatusHistory.clear();
      unawaited(navigatorKey.currentState!.pushNamed('/b'));
      await tester.pump();
      expect(transitionStatusHistory, [
        isForwardTransition(
          originRoute: isModalRoute(name: '/a'),
          destinationRoute: isModalRoute(name: '/b'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as ForwardTransition).animation,
      );
      transitionStatusHistory.clear();

      await tester.pumpAndSettle();
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: '/b'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: true));
    });

    testWidgets('When popping a route', (tester) async {
      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('/b'));
      await tester.pumpAndSettle();
      transitionStatusHistory.clear();
      navigatorKey.currentState!.pop();
      await tester.pump();
      expect(transitionStatusHistory, [
        isBackwardTransition(
          originRoute: isModalRoute(name: '/b'),
          destinationRoute: isModalRoute(name: '/a'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as BackwardTransition).animation,
      );
      transitionStatusHistory.clear();

      await tester.pumpAndSettle();
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: '/a'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: true));
    });

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('/b'));
      await tester.pumpAndSettle();
      transitionStatusHistory.clear();
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(transitionStatusHistory, [
        isUserGestureTransition(
          currentRoute: isModalRoute(name: '/b'),
          previousRoute: isModalRoute(name: '/a'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as UserGestureTransition).animation,
      );
      transitionStatusHistory.clear();

      // Move the finger toward the right side of the screen.
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(transitionStatusHistory, isEmpty);
      expect(transitionProgressHistory, isMonotonic(increasing: true));

      // End the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(transitionStatusHistory, [
        isBackwardTransition(
          originRoute: isModalRoute(name: '/b'),
          destinationRoute: isModalRoute(name: '/a'),
        ),
        isTransitionCompleted(
          currentRoute: isModalRoute(name: '/a'),
        ),
      ]);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('When iOS swipe back gesture is canceled', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('/b'));
      await tester.pumpAndSettle();
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      startTrackingTransitionProgress(
        (transitionStatusHistory.last as UserGestureTransition).animation,
      );
      transitionStatusHistory.clear();

      // Cancel the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: '/b'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: false));

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Transition event capturing test with declarative navigator API', () {
    late ValueSetter<String> setLocation;
    late Widget testWidget;

    setUp(() {
      const pageA = MaterialPage<dynamic>(
        name: 'a',
        key: ValueKey('a'),
        child: Scaffold(),
      );
      const pageB = MaterialPage<dynamic>(
        name: 'b',
        key: ValueKey('b'),
        child: Scaffold(),
      );
      const pageC = MaterialPage<dynamic>(
        name: 'c',
        key: ValueKey('c'),
        child: Scaffold(),
      );
      const pageD = MaterialPage<dynamic>(
        name: 'd',
        key: ValueKey('d'),
        child: Scaffold(),
      );

      var location = '/a';
      testWidget = StatefulBuilder(
        builder: (_, setState) {
          setLocation = (newLocation) {
            location = newLocation;
            setState(() {});
          };

          return MaterialApp(
            home: _TestRouteTransitionObserverWidget(
              onTransitionStatusChanged: transitionStatusHistory.add,
              transitionObserver: transitionObserver,
              child: Navigator(
                observers: [transitionObserver],
                onDidRemovePage: (page) {},
                pages: switch (location) {
                  '/a' => [pageA],
                  '/a/b' => [pageA, pageB],
                  '/a/b/c' => [pageA, pageB, pageC],
                  '/d' => [pageD],
                  _ => throw StateError('Unknown location: $location'),
                },
              ),
            ),
          );
        },
      );
    });

    testWidgets('On initial build', (tester) async {
      await tester.pumpWidget(testWidget);
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'a'),
        ),
      ]);
    });

    testWidgets('When pushing a route', (tester) async {
      await tester.pumpWidget(testWidget);
      transitionStatusHistory.clear();
      setLocation('/a/b');
      await tester.pump();
      expect(transitionStatusHistory, [
        isForwardTransition(
          originRoute: isModalRoute(name: 'a'),
          destinationRoute: isModalRoute(name: 'b'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as ForwardTransition).animation,
      );
      transitionStatusHistory.clear();

      await tester.pumpAndSettle();
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'b'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: true));
    });

    testWidgets('When pushing multiple routes simultaneously', (tester) async {
      await tester.pumpWidget(testWidget);
      transitionStatusHistory.clear();
      setLocation('/a/b/c');
      await tester.pump();
      expect(transitionStatusHistory, [
        isForwardTransition(
          originRoute: isModalRoute(name: 'a'),
          destinationRoute: isModalRoute(name: 'c'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as ForwardTransition).animation,
      );
      transitionStatusHistory.clear();

      await tester.pumpAndSettle();
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'c'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: true));
    });

    testWidgets('When replacing the entire page stack', (tester) async {
      await tester.pumpWidget(testWidget);
      transitionStatusHistory.clear();
      setLocation('/d');
      await tester.pump();
      expect(transitionStatusHistory, [
        isForwardTransition(
          originRoute: isModalRoute(name: 'a'),
          destinationRoute: isModalRoute(name: 'd'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as ForwardTransition).animation,
      );
      transitionStatusHistory.clear();

      await tester.pumpAndSettle();
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'd'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: true));
    });

    testWidgets('When popping a route', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();
      transitionStatusHistory.clear();
      setLocation('/a');
      await tester.pump();
      expect(transitionStatusHistory, [
        isBackwardTransition(
          originRoute: isModalRoute(name: 'b'),
          destinationRoute: isModalRoute(name: 'a'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as BackwardTransition).animation,
      );
      transitionStatusHistory.clear();

      await tester.pumpAndSettle();
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'a'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: true));
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b/c');
      await tester.pumpAndSettle();
      transitionStatusHistory.clear();
      setLocation('/a');
      await tester.pump();
      expect(transitionStatusHistory, [
        isBackwardTransition(
          originRoute: isModalRoute(name: 'c'),
          destinationRoute: isModalRoute(name: 'a'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as BackwardTransition).animation,
      );
      transitionStatusHistory.clear();

      await tester.pumpAndSettle();
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'a'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: true));
    });

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();
      transitionStatusHistory.clear();
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(transitionStatusHistory, [
        isUserGestureTransition(
          currentRoute: isModalRoute(name: 'b'),
          previousRoute: isModalRoute(name: 'a'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as UserGestureTransition).animation,
      );
      transitionStatusHistory.clear();

      // Move the finger toward the right side of the screen.
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(transitionStatusHistory, isEmpty);
      expect(transitionProgressHistory, isMonotonic(increasing: true));

      // End the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(transitionStatusHistory, [
        isBackwardTransition(
          originRoute: isModalRoute(name: 'b'),
          destinationRoute: isModalRoute(name: 'a'),
        ),
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'a'),
        ),
      ]);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('When iOS swipe back gesture is canceled on iOS',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      startTrackingTransitionProgress(
        (transitionStatusHistory.last as UserGestureTransition).animation,
      );
      transitionStatusHistory.clear();

      // Cancel the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'b'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: false));

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

class _TestRouteTransitionObserverWidget extends StatefulWidget
    with RouteTransitionAwareWidgetMixin {
  const _TestRouteTransitionObserverWidget({
    required this.onTransitionStatusChanged,
    required this.transitionObserver,
    required this.child,
  });

  final ValueChanged<RouteTransitionStatus> onTransitionStatusChanged;
  final Widget child;

  @override
  final RouteTransitionObserver transitionObserver;

  @override
  State<_TestRouteTransitionObserverWidget> createState() =>
      _TestRouteTransitionObserverWidgetState();
}

class _TestRouteTransitionObserverWidgetState
    extends State<_TestRouteTransitionObserverWidget>
    with RouteTransitionAwareStateMixin {
  @override
  void didChangeTransitionStatus(RouteTransitionStatus transition) {
    widget.onTransitionStatusChanged(transition);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
