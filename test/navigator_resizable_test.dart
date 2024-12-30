import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resizable_navigator/src/navigator_resizable.dart';
import 'package:resizable_navigator/src/resizable_navigator_routes.dart';
import 'package:resizable_navigator/src/route_transition_observer.dart';

void main() {
  group('Layout test with imperative navigator API', () {
    const interpolationCurve = Curves.easeInOut;
    final routes = {
      'a': () => const _TestRouteWidget(size: Size(100, 200)),
      'b': () => const _TestRouteWidget(size: Size(200, 300)),
    };

    late GlobalKey<NavigatorState> navigatorKey;
    late RenderBox Function(WidgetTester) getBox;
    late Widget testWidget;

    setUp(() {
      navigatorKey = GlobalKey();
      final navigatorResizableKey = UniqueKey();
      final transitionObserver = RouteTransitionObserver();

      testWidget = MaterialApp(
        home: Align(
          alignment: Alignment.center,
          child: NavigatorResizable(
            key: navigatorResizableKey,
            transitionObserver: transitionObserver,
            interpolationCurve: interpolationCurve,
            child: Navigator(
              key: navigatorKey,
              observers: [transitionObserver],
              initialRoute: 'a',
              onGenerateRoute: (settings) {
                return ResizableMaterialPageRoute(
                  settings: settings,
                  builder: (_) => routes[settings.name]!(),
                );
              },
            ),
          ),
        ),
      );

      getBox = (tester) {
        return tester.renderObject(find.byKey(navigatorResizableKey));
      };
    });

    testWidgets('After initial build', (tester) async {
      await tester.pumpWidget(testWidget);
      expect(getBox(tester).size, const Size(100, 200));
    });

    testWidgets('When pushing a new route', (tester) async {
      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pump();
      expect(getBox(tester).size, const Size(100, 200));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(100, 200),
          const Size(200, 300),
          interpolationCurve.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(getBox(tester).size, const Size(200, 300));
    });

    testWidgets('When popping a route', (tester) async {
      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();
      navigatorKey.currentState!.pop();
      await tester.pump();
      expect(getBox(tester).size, const Size(200, 300));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(200, 300),
          const Size(100, 200),
          interpolationCurve.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(getBox(tester).size, const Size(100, 200));
    });

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();

      final transitionProgress =
          navigatorKey.currentState!.currentRoute.animation!;

      // Start the swipe back gesture.
      // We assume that the screen size is 800x600.
      final gesture = await tester.startGesture(const Offset(300, 300));
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(transitionProgress.value, moreOrLessEquals(0.9));
      expect(getBox(tester).size, const Size(190, 290));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.8));
      expect(getBox(tester).size, const Size(180, 280));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.7));
      expect(getBox(tester).size, const Size(170, 270));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.6));
      expect(getBox(tester).size, const Size(160, 260));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.5));
      expect(getBox(tester).size, const Size(150, 250));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.4));
      expect(getBox(tester).size, const Size(140, 240));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(getBox(tester).size, const Size(100, 200));

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('When iOS swipe back gesture is canceled', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      unawaited(navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();

      final transitionProgress =
          navigatorKey.currentState!.currentRoute.animation!;

      // Start the swipe back gesture.
      // We assume that the screen size is 800x600.
      final gesture = await tester.startGesture(const Offset(300, 300));
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(transitionProgress.value, moreOrLessEquals(0.9));
      expect(getBox(tester).size, const Size(190, 290));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(getBox(tester).size, const Size(200, 300));

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Layout test with declarative navigator API', () {
    const interpolationCurve = Curves.easeInOut;
    late GlobalKey<NavigatorState> navigatorKey;
    late RenderBox Function(WidgetTester) getBox;
    late ValueSetter<String> setLocation;
    late Widget testWidget;

    setUp(() {
      const pageA = ResizableMaterialPage(
        name: 'a',
        key: ValueKey('a'),
        child: _TestRouteWidget(size: Size(100, 200)),
      );
      const pageB = ResizableMaterialPage(
        name: 'b',
        key: ValueKey('b'),
        child: _TestRouteWidget(size: Size(200, 300)),
      );
      const pageC = ResizableMaterialPage(
        name: 'c',
        key: ValueKey('c'),
        child: _TestRouteWidget(size: Size.infinite),
      );
      const pageD = ResizableMaterialPage(
        name: 'd',
        key: ValueKey('d'),
        child: _TestRouteWidget(size: Size(300, 400)),
      );

      navigatorKey = GlobalKey();
      final navigatorResizableKey = UniqueKey();
      final transitionObserver = RouteTransitionObserver();
      var location = '/a';
      testWidget = MaterialApp(
        home: Center(
          child: NavigatorResizable(
            key: navigatorResizableKey,
            transitionObserver: transitionObserver,
            interpolationCurve: interpolationCurve,
            child: StatefulBuilder(
              builder: (_, setState) {
                setLocation = (newLocation) {
                  location = newLocation;
                  setState(() {});
                };

                return Navigator(
                  key: navigatorKey,
                  observers: [transitionObserver],
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
        ),
      );

      getBox = (tester) {
        return tester.renderObject(find.byKey(navigatorResizableKey));
      };
    });

    testWidgets('After initial build', (tester) async {
      await tester.pumpWidget(testWidget);
      expect(getBox(tester).size, const Size(100, 200));
    });

    testWidgets('When pushing a new route', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pump();
      expect(getBox(tester).size, const Size(100, 200));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(100, 200),
          const Size(200, 300),
          interpolationCurve.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(getBox(tester).size, const Size(200, 300));
    });

    testWidgets('When pushing multiple routes simultaneously', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b/c');
      await tester.pump();
      expect(getBox(tester).size, const Size(100, 200));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(100, 200),
          // The size of the page C should be the same as the screen size.
          const Size(800, 600),
          interpolationCurve.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(getBox(tester).size, const Size(800, 600));
    });

    testWidgets('When popping a route', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();
      setLocation('/a');
      await tester.pump();
      expect(getBox(tester).size, const Size(200, 300));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(200, 300),
          const Size(100, 200),
          interpolationCurve.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(getBox(tester).size, const Size(100, 200));
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/a/b/c');
      await tester.pumpAndSettle();
      setLocation('/a');
      await tester.pump();
      expect(
        getBox(tester).size,
        const Size(800, 600),
        reason: 'The size of the page C should be the same as the screen size.',
      );

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(800, 600),
          const Size(100, 200),
          interpolationCurve.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(getBox(tester).size, const Size(100, 200));
    });

    testWidgets('When replacing the entire page stack', (tester) async {
      await tester.pumpWidget(testWidget);
      setLocation('/d');
      await tester.pump();
      expect(getBox(tester).size, const Size(100, 200));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(100, 200),
          const Size(300, 400),
          interpolationCurve.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(getBox(tester).size, const Size(300, 400));
    });

    testWidgets('When iOS swipe back gesture is performed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();

      final transitionProgress =
          navigatorKey.currentState!.currentRoute.animation!;

      // Start the swipe back gesture.
      // We assume that the screen size is 800x600.
      final gesture = await tester.startGesture(const Offset(300, 300));
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(transitionProgress.value, moreOrLessEquals(0.9));
      expect(getBox(tester).size, const Size(190, 290));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.8));
      expect(getBox(tester).size, const Size(180, 280));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.7));
      expect(getBox(tester).size, const Size(170, 270));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.6));
      expect(getBox(tester).size, const Size(160, 260));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.5));
      expect(getBox(tester).size, const Size(150, 250));

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(transitionProgress.value, moreOrLessEquals(0.4));
      expect(getBox(tester).size, const Size(140, 240));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(getBox(tester).size, const Size(100, 200));

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('When iOS swipe back gesture is canceled', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(testWidget);
      setLocation('/a/b');
      await tester.pumpAndSettle();

      final transitionProgress =
          navigatorKey.currentState!.currentRoute.animation!;

      // Start the swipe back gesture.
      // We assume that the screen size is 800x600.
      final gesture = await tester.startGesture(const Offset(300, 300));
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      expect(navigatorKey.currentState!.userGestureInProgress, isTrue);
      expect(transitionProgress.value, moreOrLessEquals(0.9));
      expect(getBox(tester).size, const Size(190, 290));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(navigatorKey.currentState!.userGestureInProgress, isFalse);
      expect(getBox(tester).size, const Size(200, 300));

      // Reset the default target platform.
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Hit testing', () {
    late bool isRouteContentTapped;
    late bool isBackgroundTapped;
    late Widget testWidget;

    setUp(() {
      isRouteContentTapped = false;
      isBackgroundTapped = false;

      final transitionObserver = RouteTransitionObserver();
      testWidget = MaterialApp(
        home: GestureDetector(
          onTap: () => isBackgroundTapped = true,
          child: ColoredBox(
            // A non-transparent background is required to detect taps.
            color: Colors.white,
            child: Center(
              child: NavigatorResizable(
                transitionObserver: transitionObserver,
                child: Navigator(
                  observers: [transitionObserver],
                  onGenerateRoute: (settings) {
                    return ResizableMaterialPageRoute(
                      settings: settings,
                      builder: (_) => GestureDetector(
                        onTap: () => isRouteContentTapped = true,
                        child: const _TestRouteWidget(
                          size: Size(200, 200),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    });

    testWidgets(
      'Tap just inside top-left corner triggers route content tap',
      (tester) async {
        await tester.pumpWidget(testWidget);
        // We assume that the screen size is 800x600.
        await tester.tapAt(const Offset(400, 300));
        expect(isRouteContentTapped, isTrue);
        expect(isBackgroundTapped, isFalse);
      },
    );

    testWidgets(
      'Tap just inside top-left corner triggers route content tap',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tapAt(const Offset(301, 201));
        expect(isRouteContentTapped, isTrue);
        expect(isBackgroundTapped, isFalse);
      },
    );

    testWidgets(
      'Tap just outside top-left corner triggers background tap',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tapAt(const Offset(299, 199));
        expect(isRouteContentTapped, isFalse);
        expect(isBackgroundTapped, isTrue);
      },
    );

    testWidgets(
      'Tap just inside top-right corner triggers route content tap',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tapAt(const Offset(499, 201));
        expect(isRouteContentTapped, isTrue);
        expect(isBackgroundTapped, isFalse);
      },
    );

    testWidgets(
      'Tap just outside top-right corner triggers background tap',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tapAt(const Offset(501, 199));
        expect(isRouteContentTapped, isFalse);
        expect(isBackgroundTapped, isTrue);
      },
    );

    testWidgets(
      'Tap just inside bottom-left corner triggers route content tap',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tapAt(const Offset(301, 399));
        expect(isRouteContentTapped, isTrue);
        expect(isBackgroundTapped, isFalse);
      },
    );

    testWidgets(
      'Tap just outside bottom-left corner triggers background tap',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tapAt(const Offset(299, 401));
        expect(isRouteContentTapped, isFalse);
        expect(isBackgroundTapped, isTrue);
      },
    );

    testWidgets(
      'Tap just inside bottom-right corner triggers route content tap',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tapAt(const Offset(499, 399));
        expect(isRouteContentTapped, isTrue);
        expect(isBackgroundTapped, isFalse);
      },
    );

    testWidgets(
      'Tap just outside bottom-right corner triggers background tap',
      (tester) async {
        await tester.pumpWidget(testWidget);
        await tester.tapAt(const Offset(501, 401));
        expect(isRouteContentTapped, isFalse);
        expect(isBackgroundTapped, isTrue);
      },
    );
  });

  testWidgets(
    'Throws assertion error when given tight constraint',
    (tester) async {
      final exceptions = <Object>[];
      final oldErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) => exceptions.add(details.exception);

      final transitionObserver = RouteTransitionObserver();
      await tester.pumpWidget(
        MaterialApp(
          home: NavigatorResizable(
            transitionObserver: transitionObserver,
            child: Navigator(
              observers: [transitionObserver],
              onGenerateRoute: (settings) {
                return ResizableMaterialPageRoute(
                  settings: settings,
                  builder: (_) => const _TestRouteWidget(
                    size: Size(200, 200),
                  ),
                );
              },
            ),
          ),
        ),
      );

      FlutterError.onError = oldErrorHandler;

      expect(
        exceptions.firstOrNull,
        isAssertionError.having(
          (it) => it.message,
          'message',
          'The NavigatorResizable widget was given an tight constraint. '
              'This is not allowed because it needs to be resized dynamically '
              'based on the size of the current route. '
              'Consider wrapping the NavigatorResizable with a widget that '
              'provides non-tight constraints, such as Align and Center. \n'
              'The given constraints were: BoxConstraints(w=800.0, h=600.0) '
              'which was given by the parent: RenderSemanticsAnnotations',
        ),
      );
    },
  );
}

class _TestRouteWidget extends StatelessWidget {
  const _TestRouteWidget({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: size.width,
      height: size.height,
    );
  }
}

extension on NavigatorState {
  ModalRoute<dynamic> get currentRoute {
    late ModalRoute<dynamic> result;
    popUntil((route) {
      result = route as ModalRoute<dynamic>;
      return true;
    });
    return result;
  }
}
