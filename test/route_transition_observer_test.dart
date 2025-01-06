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
    late Widget testWidget;
    late GlobalKey<NavigatorState> navigatorKey;
    late MockNavigatorEventListener listener;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      listener = MockNavigatorEventListener();
      testWidget = MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: 'a',
        onGenerateRoute: (settings) {
          return _TestMaterialPageRoute(
            settings: settings,
            builder: (_) => _TestScaffold(
              title: 'Page:${settings.name}',
            ),
          );
        },
        builder: (context, navigator) {
          return NavigatorEventObserver(
            listeners: [listener],
            child: navigator!,
          );
        },
      );
    });

    testWidgets('On initial build', (tester) async {
      await tester.pumpWidget(testWidget);
      expect(find.text('Page:a'), findsOneWidget);
      verifyInOrder([
        listener.didInstall(argThat(isModalRoute(name: 'a'))),
        listener.didAdd(argThat(isModalRoute(name: 'a'))),
        listener.didEndTransition(argThat(isModalRoute(name: 'a'))),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isNull),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'a')),
          argThat(isNull),
        ),
      ]);
      verifyNoMoreInteractions(listener);
    });

    testWidgets('When pushing a route', (tester) async {
      await tester.pumpWidget(testWidget);
      reset(listener);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pump();

      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      final results = verifyInOrder([
        listener.didInstall(argThat(isModalRoute(name: 'b'))),
        listener.didPush(argThat(isModalRoute(name: 'b'))),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
        ),
      ]);
      verifyNoMoreInteractions(listener);

      final capturedAnimation = results[2].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.forward);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(listener);
    });

    testWidgets(
      'When pushing multiple routes simultaneously',
      (tester) async {
        await tester.pumpWidget(testWidget);
        reset(listener);
        unawaited(navigatorKey.currentState!.pushNamed('b'));
        unawaited(navigatorKey.currentState!.pushNamed('c'));
        await tester.pump();

        final results = verifyInOrder([
          listener.didInstall(
            argThat(isModalRoute(name: 'b')),
          ),
          listener.didPush(
            argThat(isModalRoute(name: 'b')),
          ),
          listener.didStartTransition(
            argThat(isModalRoute(name: 'a')),
            argThat(isModalRoute(name: 'b')),
            any,
            isUserGestureInProgress: false,
          ),
          listener.didChangeNext(
            argThat(isModalRoute(name: 'b')),
            argThat(isNull),
          ),
          listener.didChangePrevious(
            argThat(isModalRoute(name: 'b')),
            argThat(isModalRoute(name: 'a')),
          ),
          listener.didChangeNext(
            argThat(isModalRoute(name: 'a')),
            argThat(isModalRoute(name: 'b')),
          ),
          listener.didInstall(
            argThat(isModalRoute(name: 'c')),
          ),
          listener.didPush(
            argThat(isModalRoute(name: 'c')),
          ),
          listener.didStartTransition(
            argThat(isModalRoute(name: 'a')),
            argThat(isModalRoute(name: 'c')),
            captureAny,
            isUserGestureInProgress: false,
          ),
          listener.didChangeNext(
            argThat(isModalRoute(name: 'c')),
            argThat(isNull),
          ),
          listener.didChangePrevious(
            argThat(isModalRoute(name: 'c')),
            argThat(isModalRoute(name: 'b')),
          ),
          listener.didChangeNext(
            argThat(isModalRoute(name: 'b')),
            argThat(isModalRoute(name: 'c')),
          ),
        ]);

        final capturedAnimation =
            results[8].captured.single as Animation<double>;
        expect(capturedAnimation.status, AnimationStatus.forward);

        startTrackingTransitionProgress(capturedAnimation);
        await tester.pumpAndSettle();

        expect(transitionProgressHistory, isMonotonicallyIncreasing);
        expect(find.text('Page:b'), findsNothing);
        expect(find.text('Page:c'), findsOneWidget);
        verify(listener.didEndTransition(
          argThat(isModalRoute(name: 'c')),
        )).called(1);
        verifyNoMoreInteractions(listener);
      },
    );

    // TODO: Add test: When pushing a route without animation
    testWidgets('When pushing a route without animation', (tester) async {});

    testWidgets('When popping a route', (tester) async {
      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();

      expect(find.text('Page:b'), findsOneWidget);
      expect(find.text('Page:a'), findsNothing);

      reset(listener);
      navigatorKey.currentState!.pop();
      await tester.pump();
      final results = verifyInOrder([
        listener.didComplete(argThat(isModalRoute(name: 'b')), argThat(isNull)),
        listener.didPop(argThat(isModalRoute(name: 'b')), argThat(isNull)),
        listener.didPopNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ]);
      verifyNoMoreInteractions(listener);

      final capturedAnimation = results[3].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.reverse);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:a'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'a')),
      )).called(1);
      verifyNoMoreInteractions(listener);
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      unawaited(navigatorKey.currentState!.pushNamed('c'));
      await tester.pumpAndSettle();
      expect(find.text('Page:c'), findsOneWidget);
      reset(listener);

      navigatorKey.currentState!.popUntil((route) => route.isFirst);
      await tester.pump();
      final results = verifyInOrder([
        listener.didComplete(
          argThat(isModalRoute(name: 'c')),
          argThat(isNull),
        ),
        listener.didPop(
          argThat(isModalRoute(name: 'c')),
          argThat(isNull),
        ),
        listener.didPopNext(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'c')),
        ),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'b')),
          any,
          isUserGestureInProgress: false,
        ),
        listener.didComplete(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didPop(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didPopNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'a')),
        ),
      ]);

      final capturedAnimation = results[7].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.reverse);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:c'), findsNothing);
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'a')),
      )).called(1);
      verifyNoMoreInteractions(listener);
    });

    // TODO: Add test: When popping a route without animation
    testWidgets('When popping a route without animation', (tester) async {});

    // TODO: Add test: When replacing the entire page stack
    testWidgets('When replacing the entire page stack', (tester) async {});

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);

      reset(listener);
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final verification = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
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
      verifyInOrder([
        listener.didComplete(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didPop(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didPopNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didEndTransition(
          argThat(isModalRoute(name: 'a')),
        ),
      ]);
      verifyNoMoreInteractions(listener);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('When iOS swipe back gesture is canceled', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();
      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);

      reset(listener);
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final verification = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
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
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(listener);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Navigator event capturing test with declarative navigator API', () {
    var initialLocation = '/a';
    late ValueSetter<String> setLocation;
    late Widget testWidget;
    late MockNavigatorEventListener listener;

    setUp(() {
      listener = MockNavigatorEventListener();

      const pageA = _TestMaterialPage(
        name: 'a',
        key: ValueKey('a'),
        child: _TestScaffold(title: 'Page:a'),
      );
      const pageB = _TestMaterialPage(
        name: 'b',
        key: ValueKey('b'),
        child: _TestScaffold(title: 'Page:b'),
      );
      const pageC = _TestMaterialPage(
        name: 'c',
        key: ValueKey('c'),
        child: _TestScaffold(title: 'Page:c'),
      );
      const pageD = _TestMaterialPage(
        name: 'd',
        key: ValueKey('d'),
        child: _TestScaffold(title: 'Page:d'),
      );

      String? location;
      testWidget = StatefulBuilder(
        builder: (_, setState) {
          setLocation = (newLocation) {
            location = newLocation;
            setState(() {});
          };

          return MaterialApp(
            home: NavigatorEventObserver(
              listeners: [listener],
              child: Navigator(
                onDidRemovePage: (page) {},
                pages: switch (location ?? initialLocation) {
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
      expect(find.text('Page:a'), findsOneWidget);
      verifyInOrder([
        listener.didInstall(
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didAdd(
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didEndTransition(
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isNull),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'a')),
          argThat(isNull),
        ),
      ]);
      verifyNoMoreInteractions(listener);
    });

    testWidgets('On initial build with multiple routes', (tester) async {
      initialLocation = '/a/b/c';
      await tester.pumpWidget(testWidget);

      expect(find.text('Page:c'), findsOneWidget);
      verifyInOrder([
        listener.didInstall(
          argThat(isModalRoute(name: 'c')),
        ),
        listener.didAdd(
          argThat(isModalRoute(name: 'c')),
        ),
        listener.didEndTransition(
          argThat(isModalRoute(name: 'c')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'c')),
          argThat(isNull),
        ),
        listener.didInstall(
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didAdd(
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didInstall(
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didAdd(
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'c')),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'a')),
          argThat(isNull),
        ),
      ]);
      verifyNoMoreInteractions(listener);
    });

    testWidgets('When pushing a route', (tester) async {
      await tester.pumpWidget(testWidget);
      reset(listener);
      setLocation('/a/b');
      await tester.pump();

      expect(find.text('Page:b'), findsOneWidget);
      final results = verifyInOrder([
        listener.didInstall(
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didPush(
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
        ),
      ]);
      verifyNoMoreInteractions(listener);

      final capturedAnimation = results[2].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.forward);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(listener);
    });

    testWidgets('When pushing multiple routes simultaneously', (tester) async {
      await tester.pumpWidget(testWidget);
      reset(listener);
      setLocation('/a/b/c');
      await tester.pump();

      expect(find.text('Page:c'), findsOneWidget);
      final results = verifyInOrder([
        listener.didInstall(
          argThat(isModalRoute(name: 'c')),
        ),
        listener.didPush(
          argThat(isModalRoute(name: 'c')),
        ),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'c')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'c')),
          argThat(isNull),
        ),
        listener.didInstall(
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'c')),
        ),
      ]);

      final capturedAnimation = results[2].captured.single as Animation<double>;
      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      verifyInOrder([
        listener.didEndTransition(argThat(isModalRoute(name: 'c'))),
        listener.didAdd(argThat(isModalRoute(name: 'b'))),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'c')),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
        ),
      ]);
      verifyNoMoreInteractions(listener);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(find.text('Page:c'), findsOneWidget);
    });

    // TODO: Add test: When pushing a route without animation
    testWidgets('When pushing a route without animation', (tester) async {});

    testWidgets('When replacing the entire page stack', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();
      expect(find.text('Page:b'), findsOneWidget);

      reset(listener);
      setLocation('/d');
      await tester.pump();
      expect(find.text('Page:d'), findsOneWidget);

      final results = verifyInOrder([
        listener.didInstall(
          argThat(isModalRoute(name: 'd')),
        ),
        listener.didPush(
          argThat(isModalRoute(name: 'd')),
        ),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'd')),
          captureAny,
          isUserGestureInProgress: false,
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'd')),
          argThat(isNull),
        ),
        listener.didComplete(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didComplete(
          argThat(isModalRoute(name: 'a')),
          argThat(isNull),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'd')),
          argThat(isNull),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'd')),
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'd')),
        ),
      ]);

      final capturedAnimation = results[2].captured.single as Animation<double>;
      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(find.text('Page:d'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'd')),
      )).called(1);
      verifyNoMoreInteractions(listener);
    });

    testWidgets('When popping a route', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();
      expect(find.text('Page:b'), findsOneWidget);

      reset(listener);
      setLocation('/a');
      await tester.pump();

      final results = verifyInOrder([
        listener.didComplete(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didPop(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didPopNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
        ),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
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
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'a')),
      )).called(1);
      verifyNoMoreInteractions(listener);
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b/c');
      await tester.pumpAndSettle();
      expect(find.text('Page:c'), findsOneWidget);
      reset(listener);

      setLocation('/a');
      await tester.pump();
      final results = verifyInOrder([
        listener.didComplete(
          argThat(isModalRoute(name: 'c')),
          argThat(isNull),
        ),
        listener.didPop(
          argThat(isModalRoute(name: 'c')),
          argThat(isNull),
        ),
        listener.didComplete(
          argThat(isModalRoute(name: 'b')),
          argThat(isNull),
        ),
        listener.didPopNext(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'c')),
        ),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'b')),
          any,
          isUserGestureInProgress: false,
        ),
        listener.didChangePrevious(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'a')),
        ),
        listener.didChangeNext(
          argThat(isModalRoute(name: 'a')),
          argThat(isNull),
        ),
        listener.didStartTransition(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ]);

      final capturedAnimation = results[7].captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.reverse);

      startTrackingTransitionProgress(capturedAnimation);
      await tester.pumpAndSettle();

      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:c'), findsNothing);
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'a')),
      )).called(1);
      verifyNoMoreInteractions(listener);
    });

    // TODO: Add test: When popping a route without animation
    testWidgets('When popping a route without animation', (tester) async {});

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();
      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);

      reset(listener);
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final verification = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
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
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(listener);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('When iOS swipe back gesture is canceled', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();
      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);

      reset(listener);
      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final verification = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
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
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'b')),
      )).called(1);
      verifyNoMoreInteractions(listener);

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

class _TestMaterialPageRoute extends MaterialPageRoute<dynamic>
    with ObservableModalRouteMixin<dynamic> {
  _TestMaterialPageRoute({super.settings, required super.builder});
}

class _TestMaterialPage extends MaterialPage<dynamic> {
  const _TestMaterialPage({
    super.key,
    super.name,
    required super.child,
  });

  @override
  Route<dynamic> createRoute(BuildContext context) =>
      _TestPageBasedMaterialPageRoute(page: this);
}

class _TestPageBasedMaterialPageRoute extends PageRoute<dynamic>
    with
        ObservableModalRouteMixin<dynamic>,
        MaterialRouteTransitionMixin<dynamic> {
  _TestPageBasedMaterialPageRoute({
    required _TestMaterialPage page,
  }) : super(settings: page);

  @override
  bool get maintainState => (settings as _TestMaterialPage).maintainState;

  @override
  bool get fullscreenDialog => (settings as _TestMaterialPage).fullscreenDialog;

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
