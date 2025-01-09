import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:resizable_navigator/src/navigator_event_observer.dart';

import 'src/matchers.dart';
import 'src/mocks.dart';

void main() {
  late List<double> transitionProgressHistory;

  setUp(() {
    transitionProgressHistory = [];
  });

  // Use the returned callback to stop tracking the transition progress.
  VoidCallback startTrackingTransitionProgress(Animation<double> progress) {
    transitionProgressHistory = [];
    void listener() => transitionProgressHistory.add(progress.value);
    progress.addListener(listener);
    return () => progress.removeListener(listener);
  }

  group('Navigator event capturing test with imperative navigator API', () {
    ({
      Widget testWidget,
      MockNavigatorEventListener listener,
      GlobalKey<NavigatorState> navigatorKey,
      ValueGetter<NavigatorEventObserverState> getObserver,
    }) boilerplate({
      Duration transitionDuration = const Duration(milliseconds: 300),
    }) {
      final navigatorKey = GlobalKey<NavigatorState>();
      final navigatorResizableKey = GlobalKey<NavigatorEventObserverState>();
      final listener = MockNavigatorEventListener();
      final testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: 'a',
        onGenerateRoute: (settings) {
          return _TestMaterialPageRoute(
            settings: settings,
            transitionDuration: transitionDuration,
            builder: (_) => _TestScaffold(
              title: 'Page:${settings.name}',
            ),
          );
        },
        builder: (context, navigator) {
          return NavigatorEventObserver(
            key: navigatorResizableKey,
            listeners: [listener],
            child: navigator!,
          );
        },
      );

      return (
        testWidget: testWidget,
        listener: listener,
        navigatorKey: navigatorKey,
        getObserver: () => navigatorResizableKey.currentState!,
      );
    }

    testWidgets('On initial build', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      expect(find.text('Page:a'), findsOneWidget);
      verifyInOrder([
        env.listener.didInstall(
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didAdd(
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didEndTransition(
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isNull),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'a')),
          argThat(isNull),
        ),
      ]);
      verifyNoMoreInteractions(env.listener);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'a'));
    });

    testWidgets('When pushing a route', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      reset(env.listener);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pump();

      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      final results = verifyInOrder([
        env.listener.didInstall(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didPush(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
      ]);
      verifyNoMoreInteractions(env.listener);

      final capturedAnimation = results[2].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.forward);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'b'));
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);
    });

    testWidgets('When pushing a route without animation', (tester) async {
      final env = boilerplate(transitionDuration: Duration.zero);
      await tester.pumpWidget(env.testWidget);
      reset(env.listener);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pump();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      verifyInOrder([
        env.listener.didInstall(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didPush(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didEndTransition(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
      ]);

      await tester.pumpAndSettle();

      verifyNoMoreInteractions(env.listener);
      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'b'));
    });

    testWidgets(
      'When pushing multiple routes simultaneously',
      (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);
        reset(env.listener);
        unawaited(env.navigatorKey.currentState!.pushNamed('b'));
        unawaited(env.navigatorKey.currentState!.pushNamed('c'));
        await tester.pump();

        final results = verifyInOrder([
          env.listener.didInstall(
            argThat(isRoute(name: 'b')),
          ),
          env.listener.didPush(
            argThat(isRoute(name: 'b')),
          ),
          env.listener.didStartTransition(
            argThat(isRoute(name: 'a')),
            argThat(isRoute(name: 'b')),
            any,
            isUserGestureInProgress: false,
          ),
          env.listener.didChangeNext(
            argThat(isRoute(name: 'b')),
            argThat(isNull),
          ),
          env.listener.didChangePrevious(
            argThat(isRoute(name: 'b')),
            argThat(isRoute(name: 'a')),
          ),
          env.listener.didChangeNext(
            argThat(isRoute(name: 'a')),
            argThat(isRoute(name: 'b')),
          ),
          env.listener.didInstall(
            argThat(isRoute(name: 'c')),
          ),
          env.listener.didPush(
            argThat(isRoute(name: 'c')),
          ),
          env.listener.didStartTransition(
            argThat(isRoute(name: 'a')),
            argThat(isRoute(name: 'c')),
            captureAny,
            isUserGestureInProgress: false,
          ),
          env.listener.didChangeNext(
            argThat(isRoute(name: 'c')),
            argThat(isNull),
          ),
          env.listener.didChangePrevious(
            argThat(isRoute(name: 'c')),
            argThat(isRoute(name: 'b')),
          ),
          env.listener.didChangeNext(
            argThat(isRoute(name: 'b')),
            argThat(isRoute(name: 'c')),
          ),
        ]);

        final capturedAnimation =
            results[8].captured.single as Animation<double>;
        expect(capturedAnimation.status, AnimationStatus.forward);

        startTrackingTransitionProgress(capturedAnimation);
        await tester.pumpAndSettle();

        expect(transitionProgressHistory, isMonotonicallyIncreasing);
        expect(env.getObserver().lastSettledRoute, isRoute(name: 'c'));
        expect(find.text('Page:b'), findsNothing);
        expect(find.text('Page:c'), findsOneWidget);
        verify(env.listener.didEndTransition(
          argThat(isRoute(name: 'c')),
        )).called(1);
        verifyNoMoreInteractions(env.listener);
      },
    );

    testWidgets('When popping a route', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();

      expect(find.text('Page:b'), findsOneWidget);
      expect(find.text('Page:a'), findsNothing);

      reset(env.listener);
      env.navigatorKey.currentState!.pop();
      await tester.pump();
      final results = verifyInOrder([
        env.listener.didComplete(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPop(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPopNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ]);
      verifyNoMoreInteractions(env.listener);

      final capturedAnimation = results[3].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.reverse);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:a'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'a'));
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'a')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);
    });

    testWidgets('When popping a route without animation', (tester) async {
      final env = boilerplate(transitionDuration: Duration.zero);
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();

      expect(find.text('Page:b'), findsOneWidget);
      expect(find.text('Page:a'), findsNothing);

      reset(env.listener);
      env.navigatorKey.currentState!.pop();
      await tester.pump();
      verifyInOrder([
        env.listener.didComplete(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPop(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPopNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didEndTransition(
          argThat(isRoute(name: 'a')),
        ),
      ]);

      await tester.pumpAndSettle();

      verifyNoMoreInteractions(env.listener);
      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:a'), findsOneWidget);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'a'));
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      unawaited(env.navigatorKey.currentState!.pushNamed('c'));
      await tester.pumpAndSettle();
      expect(find.text('Page:c'), findsOneWidget);
      reset(env.listener);

      env.navigatorKey.currentState!.popUntil((route) => route.isFirst);
      await tester.pump();

      final results = verifyInOrder([
        env.listener.didComplete(
          argThat(isRoute(name: 'c')),
          argThat(isNull),
        ),
        env.listener.didPop(
          argThat(isRoute(name: 'c')),
          argThat(isNull),
        ),
        env.listener.didPopNext(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'c')),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'c')),
          argThat(isRoute(name: 'b')),
          any,
          isUserGestureInProgress: false,
        ),
        env.listener.didComplete(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPop(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPopNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'c')),
          argThat(isRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'c')),
          argThat(isRoute(name: 'a')),
        ),
      ]);

      final capturedAnimation = results[7].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.reverse);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'a'));
      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:c'), findsNothing);
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'a')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);
    });

    testWidgets('When replacing the entire page stack', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      reset(env.listener);
      unawaited(env.navigatorKey.currentState!.pushReplacementNamed('b'));
      await tester.pump();

      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      final results = verifyInOrder([
        env.listener.didInstall(argThat(isRoute(name: 'b'))),
        env.listener.didPush(argThat(isRoute(name: 'b'))),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didComplete(
          argThat(isRoute(name: 'a')),
          argThat(isNull),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
      ]);
      verifyNoMoreInteractions(env.listener);

      final capturedAnimation = results[2].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.forward);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'b'));
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);
    });

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);

      reset(env.listener);
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final verification = verify(
        env.listener.didStartTransition(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: true,
        ),
      )..called(1);
      final capturedAnimation =
          verification.captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.forward);

      startTrackingTransitionProgress(capturedAnimation);

      // Move the finger toward the right side of the screen.
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(200, 0));
      await tester.pumpAndSettle();
      // End the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'a'));
      verifyInOrder([
        env.listener.didComplete(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPop(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPopNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didEndTransition(
          argThat(isRoute(name: 'a')),
        ),
      ]);
      verifyNoMoreInteractions(env.listener);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('When iOS swipe back gesture is canceled', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();
      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);

      reset(env.listener);
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final verification = verify(
        env.listener.didStartTransition(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: true,
        ),
      )..called(1);
      final capturedAnimation =
          verification.captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      // Cancel the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'b'));
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Navigator event capturing test with declarative navigator API', () {
    ({
      Widget testWidget,
      MockNavigatorEventListener listener,
      ValueSetter<String> setLocation,
      ValueGetter<NavigatorEventObserverState> getObserver,
    }) boilerplate({
      String initialLocation = '/a',
      Duration transitionDuration = const Duration(milliseconds: 300),
    }) {
      final pageA = _TestMaterialPage(
        name: 'a',
        key: const ValueKey('a'),
        transitionDuration: transitionDuration,
        child: const _TestScaffold(title: 'Page:a'),
      );
      final pageB = _TestMaterialPage(
        name: 'b',
        key: const ValueKey('b'),
        transitionDuration: transitionDuration,
        child: const _TestScaffold(title: 'Page:b'),
      );
      final pageC = _TestMaterialPage(
        name: 'c',
        key: const ValueKey('c'),
        transitionDuration: transitionDuration,
        child: const _TestScaffold(title: 'Page:c'),
      );
      final pageD = _TestMaterialPage(
        name: 'd',
        key: const ValueKey('d'),
        transitionDuration: transitionDuration,
        child: const _TestScaffold(title: 'Page:d'),
      );

      var location = initialLocation;
      late VoidCallback invokeSetState;
      void setLocation(String newLocation) {
        location = newLocation;
        invokeSetState();
      }

      final listener = MockNavigatorEventListener();
      final observerKey = GlobalKey<NavigatorEventObserverState>();
      final testWidget = StatefulBuilder(
        builder: (_, setState) {
          return MaterialApp(
            home: NavigatorEventObserver(
              key: observerKey,
              listeners: [listener],
              child: StatefulBuilder(
                builder: (_, setState) {
                  invokeSetState = () => setState(() {});
                  return Navigator(
                    onDidRemovePage: (page) {},
                    pages: switch (location) {
                      '/a' => [pageA],
                      '/a/b' => [pageA, pageB],
                      '/a/b/c' => [pageA, pageB, pageC],
                      '/d' => [pageD],
                      _ => throw StateError('Unknown location: $location'),
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      return (
        testWidget: testWidget,
        listener: listener,
        setLocation: setLocation,
        getObserver: () => observerKey.currentState!,
      );
    }

    testWidgets('On initial build', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      expect(find.text('Page:a'), findsOneWidget);
      verifyInOrder([
        env.listener.didInstall(
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didAdd(
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didEndTransition(
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isNull),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'a')),
          argThat(isNull),
        ),
      ]);
      verifyNoMoreInteractions(env.listener);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'a'));
    });

    testWidgets('On initial build with multiple routes', (tester) async {
      final env = boilerplate(initialLocation: '/a/b/c');
      await tester.pumpWidget(env.testWidget);

      expect(find.text('Page:c'), findsOneWidget);
      verifyInOrder([
        env.listener.didInstall(
          argThat(isRoute(name: 'c')),
        ),
        env.listener.didAdd(
          argThat(isRoute(name: 'c')),
        ),
        env.listener.didEndTransition(
          argThat(isRoute(name: 'c')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'c')),
          argThat(isNull),
        ),
        env.listener.didInstall(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didAdd(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didInstall(
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didAdd(
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'c')),
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'c')),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'a')),
          argThat(isNull),
        ),
      ]);
      verifyNoMoreInteractions(env.listener);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'c'));
    });

    testWidgets('When pushing a route', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      reset(env.listener);
      env.setLocation('/a/b');
      await tester.pump();

      expect(find.text('Page:b'), findsOneWidget);
      final results = verifyInOrder([
        env.listener.didInstall(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didPush(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
      ]);
      verifyNoMoreInteractions(env.listener);

      final capturedAnimation = results[2].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.forward);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'b'));
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);
    });

    testWidgets('When pushing a route without animation', (tester) async {
      final env = boilerplate(transitionDuration: Duration.zero);
      await tester.pumpWidget(env.testWidget);
      reset(env.listener);
      env.setLocation('/a/b');
      await tester.pump();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      verifyInOrder([
        env.listener.didInstall(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didPush(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didEndTransition(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
      ]);

      await tester.pumpAndSettle();

      verifyNoMoreInteractions(env.listener);
      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'b'));
    });

    testWidgets('When pushing multiple routes simultaneously', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      reset(env.listener);
      env.setLocation('/a/b/c');
      await tester.pump();

      expect(find.text('Page:c'), findsOneWidget);
      final results = verifyInOrder([
        env.listener.didInstall(
          argThat(isRoute(name: 'c')),
        ),
        env.listener.didPush(
          argThat(isRoute(name: 'c')),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'c')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'c')),
          argThat(isNull),
        ),
        env.listener.didInstall(
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'c')),
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'c')),
        ),
      ]);

      final capturedAnimation = results[2].captured.single as Animation<double>;
      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      verifyInOrder([
        env.listener.didEndTransition(argThat(isRoute(name: 'c'))),
        env.listener.didAdd(argThat(isRoute(name: 'b'))),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'c')),
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'c')),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
      ]);
      verifyNoMoreInteractions(env.listener);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'c'));
      expect(find.text('Page:c'), findsOneWidget);
    });

    testWidgets('When replacing the entire page stack', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/a/b');
      await tester.pumpAndSettle();
      expect(find.text('Page:b'), findsOneWidget);

      reset(env.listener);
      env.setLocation('/d');
      await tester.pump();
      expect(find.text('Page:d'), findsOneWidget);

      final results = verifyInOrder([
        env.listener.didInstall(
          argThat(isRoute(name: 'd')),
        ),
        env.listener.didPush(
          argThat(isRoute(name: 'd')),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'd')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'd')),
          argThat(isNull),
        ),
        env.listener.didComplete(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didComplete(
          argThat(isRoute(name: 'a')),
          argThat(isNull),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'd')),
          argThat(isNull),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'd')),
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'd')),
        ),
      ]);

      final capturedAnimation = results[2].captured.single as Animation<double>;
      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:d'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'd'));
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'd')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);
    });

    testWidgets('When popping a route', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/a/b');
      await tester.pumpAndSettle();
      expect(find.text('Page:b'), findsOneWidget);

      reset(env.listener);
      env.setLocation('/a');
      await tester.pump();

      final results = verifyInOrder([
        env.listener.didComplete(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPop(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPopNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ]);

      final capturedAnimation = results[3].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.reverse);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:a'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'a'));
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'a')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);
    });

    testWidgets('When popping a route without animation', (tester) async {
      final env = boilerplate(
        initialLocation: '/a/b',
        transitionDuration: Duration.zero,
      );

      await tester.pumpWidget(env.testWidget);
      expect(find.text('Page:b'), findsOneWidget);

      reset(env.listener);
      env.setLocation('/a');
      await tester.pump();

      verifyInOrder([
        env.listener.didComplete(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPop(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPopNext(
          argThat(isRoute(name: 'a')),
          argThat(isRoute(name: 'b')),
        ),
        env.listener.didEndTransition(
          argThat(isRoute(name: 'a')),
        ),
      ]);

      await tester.pumpAndSettle();

      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:a'), findsOneWidget);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'a'));
      verifyNoMoreInteractions(env.listener);
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/a/b/c');
      await tester.pumpAndSettle();
      expect(find.text('Page:c'), findsOneWidget);
      reset(env.listener);

      env.setLocation('/a');
      await tester.pump();
      final results = verifyInOrder([
        env.listener.didComplete(
          argThat(isRoute(name: 'c')),
          argThat(isNull),
        ),
        env.listener.didPop(
          argThat(isRoute(name: 'c')),
          argThat(isNull),
        ),
        env.listener.didComplete(
          argThat(isRoute(name: 'b')),
          argThat(isNull),
        ),
        env.listener.didPopNext(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'c')),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'c')),
          argThat(isRoute(name: 'b')),
          any,
          isUserGestureInProgress: false,
        ),
        env.listener.didChangePrevious(
          argThat(isRoute(name: 'c')),
          argThat(isRoute(name: 'a')),
        ),
        env.listener.didChangeNext(
          argThat(isRoute(name: 'a')),
          argThat(isNull),
        ),
        env.listener.didStartTransition(
          argThat(isRoute(name: 'c')),
          argThat(isRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ]);

      final capturedAnimation = results[7].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.reverse);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'a'));
      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:c'), findsNothing);
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'a')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);
    });

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/a/b');
      await tester.pumpAndSettle();
      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);

      reset(env.listener);
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final verification = verify(
        env.listener.didStartTransition(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: true,
        ),
      )..called(1);
      final capturedAnimation =
          verification.captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      // Cancel the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'b'));
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('When iOS swipe back gesture is canceled', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/a/b');
      await tester.pumpAndSettle();
      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);

      reset(env.listener);
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final verification = verify(
        env.listener.didStartTransition(
          argThat(isRoute(name: 'b')),
          argThat(isRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: true,
        ),
      )..called(1);
      final capturedAnimation =
          verification.captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      // Cancel the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(env.getObserver().lastSettledRoute, isRoute(name: 'b'));
      verify(env.listener.didEndTransition(
        argThat(isRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(env.listener);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

class _TestMaterialPageRoute extends MaterialPageRoute<dynamic>
    with ObservableRouteMixin<dynamic> {
  _TestMaterialPageRoute({
    super.settings,
    required this.transitionDuration,
    required super.builder,
  });

  @override
  final Duration transitionDuration;
}

class _TestMaterialPage extends MaterialPage<dynamic> {
  const _TestMaterialPage({
    super.key,
    super.name,
    required this.transitionDuration,
    required super.child,
  });

  final Duration transitionDuration;

  @override
  Route<dynamic> createRoute(BuildContext context) =>
      _TestPageBasedMaterialPageRoute(page: this);
}

class _TestPageBasedMaterialPageRoute extends PageRoute<dynamic>
    with ObservableRouteMixin<dynamic>, MaterialRouteTransitionMixin<dynamic> {
  _TestPageBasedMaterialPageRoute({
    required _TestMaterialPage page,
  }) : super(settings: page);

  @override
  bool get maintainState => (settings as _TestMaterialPage).maintainState;

  @override
  bool get fullscreenDialog => (settings as _TestMaterialPage).fullscreenDialog;

  @override
  Duration get transitionDuration =>
      (settings as _TestMaterialPage).transitionDuration;

  @override
  Widget buildContent(BuildContext context) =>
      (settings as _TestMaterialPage).child;
}

class _TestScaffold extends StatelessWidget {
  const _TestScaffold({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
    );
  }
}
