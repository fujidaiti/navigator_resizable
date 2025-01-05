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

  group('Transition event capturing test with imperative navigator API', () {
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
      verify(listener.didInstall(argThat(isModalRoute(name: 'a'))));
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'a'))));
    });

    testWidgets('When pushing a route', (tester) async {
      await tester.pumpWidget(testWidget);
      reset(listener);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pump();

      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
          captureAny,
        ),
      ).captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.forward);

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'b'))));
    });

    testWidgets('When popping a route', (tester) async {
      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();

      expect(find.text('Page:b'), findsOneWidget);
      expect(find.text('Page:a'), findsNothing);

      reset(listener);
      navigatorKey.currentState!.pop();
      await tester.pump();
      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
        ),
      ).captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.reverse);

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);
      await tester.pumpAndSettle();

      expect(find.text('Page:b'), findsNothing);
      expect(find.text('Page:a'), findsOne);
      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'a'))));
    });

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

      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: true,
        ),
      ).captured.single as Animation<double>;
      expect(capturedAnimation.status, AnimationStatus.forward);

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);

      // Move the finger toward the right side of the screen.
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(transitionProgressHistory, isMonotonicallyDecreasing);

      transitionProgressHistory.clear();
      reset(listener);
      // End the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsOne);
      expect(find.text('Page:b'), findsNothing);
      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'a'))));

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

      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: true,
        ),
      ).captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);
      // Cancel the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'b'))));

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Transition event capturing test with declarative navigator API', () {
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

      var location = '/a';
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
      expect(find.text('Page:a'), findsOneWidget);
      verify(listener.didInstall(argThat(isModalRoute(name: 'a'))));
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'a'))));
    });

    testWidgets('When pushing a route', (tester) async {
      await tester.pumpWidget(testWidget);
      expect(find.text('Page:a'), findsOneWidget);
      reset(listener);
      setLocation('/a/b');
      await tester.pump();
      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'b')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ).captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);

      await tester.pumpAndSettle();
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(find.text('Page:b'), findsOneWidget);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'b'))));
    });

    testWidgets('When pushing multiple routes simultaneously', (tester) async {
      await tester.pumpWidget(testWidget);
      reset(listener);
      setLocation('/a/b/c');
      await tester.pump();
      expect(find.text('Page:c'), findsOneWidget);

      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'c')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ).captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);

      await tester.pumpAndSettle();
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      expect(find.text('Page:c'), findsOneWidget);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'c'))));
    });

    testWidgets('When replacing the entire page stack', (tester) async {
      await tester.pumpWidget(testWidget);
      reset(listener);
      setLocation('/d');
      await tester.pump();
      expect(find.text('Page:d'), findsOneWidget);

      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'a')),
          argThat(isModalRoute(name: 'd')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ).captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);

      await tester.pumpAndSettle();
      expect(find.text('Page:d'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'd'))));
    });

    testWidgets('When popping a route', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();
      expect(find.text('Page:b'), findsOneWidget);
      reset(listener);
      setLocation('/a');
      await tester.pump();
      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ).captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);

      await tester.pumpAndSettle();
      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      expect(find.text('Page:a'), findsOneWidget);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'a'))));
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b/c');
      await tester.pumpAndSettle();
      expect(find.text('Page:c'), findsOneWidget);
      reset(listener);

      setLocation('/a');
      await tester.pump();
      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'c')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: false,
        ),
      ).captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);

      await tester.pumpAndSettle();
      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      expect(find.text('Page:a'), findsOneWidget);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'a'))));
    });

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

      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: true,
        ),
      ).captured.single as Animation<double>;

      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);

      // Move the finger toward the right side of the screen.
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();
      await gesture.moveBy(const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(transitionProgressHistory, isMonotonicallyDecreasing);

      // End the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsOneWidget);
      expect(find.text('Page:b'), findsNothing);
      expect(transitionProgressHistory, isMonotonicallyDecreasing);
      verify(listener.didEndTransition(
        argThat(isModalRoute(name: 'a')),
      )).called(1);

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

      // Start a swipe back gesture
      final gesture = await tester.startGesture(const Offset(0, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pumpAndSettle();

      final capturedAnimation = verify(
        listener.didStartTransition(
          argThat(isModalRoute(name: 'b')),
          argThat(isModalRoute(name: 'a')),
          captureAny,
          isUserGestureInProgress: true,
        ),
      ).captured.single as Animation<double>;
      startTrackingTransitionProgress(capturedAnimation);
      reset(listener);

      // Cancel the swipe back gesture.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page:a'), findsNothing);
      expect(find.text('Page:b'), findsOneWidget);
      expect(transitionProgressHistory, isMonotonicallyIncreasing);
      verify(listener.didEndTransition(argThat(isModalRoute(name: 'b'))));

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
      _PageBasedResizableMaterialPageRoute(page: this);
}

class _PageBasedResizableMaterialPageRoute extends PageRoute<dynamic>
    with
        ObservableModalRouteMixin<dynamic>,
        MaterialRouteTransitionMixin<dynamic> {
  _PageBasedResizableMaterialPageRoute({
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
