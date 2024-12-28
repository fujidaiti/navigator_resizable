import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

  group('Imperative Navigator API test', () {
    late Widget testWidget;

    setUp(() {
      Route<dynamic> createSecondRoute() {
        return MaterialPageRoute(
          settings: const RouteSettings(name: 'second'),
          builder: (context) {
            return _TestRouteWidget(
              onBack: () => Navigator.pop(context),
            );
          },
        );
      }

      Route<dynamic> createFirstRoute() {
        return MaterialPageRoute(
          settings: const RouteSettings(name: 'first'),
          builder: (context) {
            return _TestRouteWidget(
              onNext: () => Navigator.push(context, createSecondRoute()),
            );
          },
        );
      }

      testWidget = MaterialApp(
        home: _TestRouteTransitionObserverWidget(
          onTransitionStatusChanged: transitionStatusHistory.add,
          transitionObserver: transitionObserver,
          child: _ImperativeNavigator(
            observer: transitionObserver,
            initialRouteBuilder: createFirstRoute,
          ),
        ),
      );
    });

    testWidgets('Detect initial build', (tester) async {
      await tester.pumpWidget(testWidget);
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'first'),
        ),
      ]);
    });

    testWidgets('Detect push events', (tester) async {
      await tester.pumpWidget(testWidget);
      transitionStatusHistory.clear();
      await tester.tap(find.text('Next'));
      expect(transitionStatusHistory, [
        isForwardTransition(
          originRoute: isModalRoute(name: 'first'),
          destinationRoute: isModalRoute(name: 'second'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as ForwardTransition).animation,
      );
      transitionStatusHistory.clear();

      await tester.pumpAndSettle();
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'second'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: true));
    });

    testWidgets('Detect pop events', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      transitionStatusHistory.clear();
      await tester.tap(find.text('Back'));
      expect(transitionStatusHistory, [
        isBackwardTransition(
          originRoute: isModalRoute(name: 'second'),
          destinationRoute: isModalRoute(name: 'first'),
        ),
      ]);

      startTrackingTransitionProgress(
        (transitionStatusHistory.first as BackwardTransition).animation,
      );
      transitionStatusHistory.clear();

      await tester.pumpAndSettle();
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'first'),
        ),
      ]);
      expect(transitionProgressHistory, isMonotonic(increasing: true));
    });

    testWidgets('Detect swipe back gesture events on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      transitionStatusHistory.clear();
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(transitionStatusHistory, [
        isUserGestureTransition(
          currentRoute: isModalRoute(name: 'second'),
          previousRoute: isModalRoute(name: 'first'),
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
          originRoute: isModalRoute(name: 'second'),
          destinationRoute: isModalRoute(name: 'first'),
        ),
        isTransitionCompleted(
          currentRoute: isModalRoute(name: 'first'),
        ),
      ]);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'Detect swipe back gesture events on iOS (canceled)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await tester.pumpWidget(testWidget);
        await tester.tap(find.text('Next'));
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
            currentRoute: isModalRoute(name: 'second'),
          ),
        ]);
        expect(transitionProgressHistory, isMonotonic(increasing: false));

        // Reset the default target platform.
        debugDefaultTargetPlatformOverride = null;
      },
    );
  });

  group('Declarative Navigator API test', () {
    late Widget testWidget;

    setUp(() {
      // TODO: Do not use GoRouter.
      final router = GoRouter(
        observers: [transitionObserver],
        initialLocation: '/a',
        routes: [
          GoRoute(
            path: '/a',
            builder: (context, _) => _TestRouteWidget(
              onNext: () => context.go('/a/b'),
            ),
            routes: [
              GoRoute(
                path: 'b',
                builder: (context, _) => _TestRouteWidget(
                  onNext: () => context.go('/a/b/c'),
                  onBack: () => context.go('/a'),
                ),
                routes: [
                  GoRoute(
                    path: 'c',
                    builder: (context, _) => _TestRouteWidget(
                      onNext: () => context.go('/A'),
                      onBack: () => context.go('/a/b'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/A',
            builder: (context, _) => const _TestRouteWidget(),
          ),
        ],
      );

      testWidget = MaterialApp.router(
        routerConfig: router,
        builder: (context, child) {
          return _TestRouteTransitionObserverWidget(
            onTransitionStatusChanged: transitionStatusHistory.add,
            transitionObserver: transitionObserver,
            child: child!,
          );
        },
      );
    });

    testWidgets('Detect initial build', (tester) async {
      await tester.pumpWidget(testWidget);
      expect(transitionStatusHistory, [
        isTransitionCompleted(
          currentRoute: isModalRoute(name: '/a'),
        ),
      ]);
    });

    testWidgets('Detect push events', (tester) async {
      await tester.pumpWidget(testWidget);
      transitionStatusHistory.clear();
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(transitionStatusHistory, [
        isForwardTransition(
          originRoute: isModalRoute(name: '/a'),
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

    testWidgets('Detect pop events', (tester) async {
      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      transitionStatusHistory.clear();
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(transitionStatusHistory, [
        isBackwardTransition(
          originRoute: isModalRoute(name: 'b'),
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

    testWidgets('Detect swipe back gesture events on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      transitionStatusHistory.clear();
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(transitionStatusHistory, [
        isUserGestureTransition(
          currentRoute: isModalRoute(name: 'b'),
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
          originRoute: isModalRoute(name: 'b'),
          destinationRoute: isModalRoute(name: '/a'),
        ),
        isTransitionCompleted(
          currentRoute: isModalRoute(name: '/a'),
        ),
      ]);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'Detect swipe back gesture events on iOS (canceled)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await tester.pumpWidget(testWidget);
        await tester.tap(find.text('Next'));
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
      },
    );
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

class _ImperativeNavigator extends StatelessWidget {
  const _ImperativeNavigator({
    this.observer,
    required this.initialRouteBuilder,
  });

  final NavigatorObserver? observer;
  final Route<dynamic> Function() initialRouteBuilder;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      observers: [if (observer != null) observer!],
      onGenerateInitialRoutes: (_, __) => [initialRouteBuilder()],
    );
  }
}

class _TestRouteWidget extends StatelessWidget {
  const _TestRouteWidget({
    this.onNext,
    this.onBack,
  });

  final VoidCallback? onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: onNext,
            child: const Text('Next'),
          ),
          TextButton(
            onPressed: onBack,
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
