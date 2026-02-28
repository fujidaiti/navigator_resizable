import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigator_resizable/src/navigator_resizable.dart';
import 'package:navigator_resizable/src/resizable_navigator_routes.dart';

void main() {
  group('Size transition test with imperative navigator API', () {
    ({
      GlobalKey<NavigatorState> navigatorKey,
      RenderBox Function(WidgetTester) getBox,
      Widget testWidget,
    }) boilerplate({
      Curve interpolationCurve = Curves.easeInOut,
    }) {
      final navigatorKey = GlobalKey<NavigatorState>();
      final navigatorResizableKey = UniqueKey();
      final routes = {
        'a': () => const _TestRouteWidget(initialSize: Size(100, 200)),
        'b': () => const _TestRouteWidget(initialSize: Size(200, 300)),
        'c': () => const _TestRouteWidget(initialSize: Size(150, 250)),
      };
      final testWidget = MaterialApp(
        home: Align(
          alignment: Alignment.center,
          child: NavigatorResizable(
            key: navigatorResizableKey,
            interpolationCurve: interpolationCurve,
            child: Navigator(
              key: navigatorKey,
              initialRoute: 'a',
              onGenerateRoute: (settings) {
                return ResizablePageRouteBuilder(
                  settings: settings,
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (_, __, ___) => routes[settings.name]!(),
                  transitionsBuilder: _testTransitionsBuilder,
                );
              },
            ),
          ),
        ),
      );

      RenderBox getBox(WidgetTester tester) {
        return tester.renderObject(find.byKey(navigatorResizableKey));
      }

      return (
        navigatorKey: navigatorKey,
        getBox: getBox,
        testWidget: testWidget,
      );
    }

    testWidgets('After initial build', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      expect(env.getBox(tester).size, const Size(100, 200));
    });

    testWidgets('When pushing a new route', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pump();
      expect(env.getBox(tester).size, const Size(100, 200));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(100, 200),
          const Size(200, 300),
          Curves.easeInOut.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(200, 300));
    });

    testWidgets('When pushing multiple routes simultaneously', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      unawaited(env.navigatorKey.currentState!.pushNamed('c'));
      await tester.pump();
      expect(env.getBox(tester).size, const Size(100, 200));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(100, 200),
          const Size(150, 250),
          Curves.easeInOut.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(150, 250));
    });

    testWidgets('When popping a route', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();
      env.navigatorKey.currentState!.pop();
      await tester.pump();
      expect(env.getBox(tester).size, const Size(200, 300));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(200, 300),
          const Size(100, 200),
          Curves.easeInOut.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(100, 200));
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      unawaited(env.navigatorKey.currentState!.pushNamed('c'));
      await tester.pumpAndSettle();
      env.navigatorKey.currentState!.popUntil((r) => r.isFirst);
      await tester.pump();
      expect(env.getBox(tester).size, const Size(150, 250));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(150, 250),
          const Size(100, 200),
          Curves.easeInOut.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(100, 200));
    });

    testWidgets(
      'When pushing a route and reverting in mid-transition',
      (tester) async {
        final env = boilerplate(interpolationCurve: Curves.linear);
        await tester.pumpWidget(env.testWidget);
        // Push b and forward the transition.
        unawaited(env.navigatorKey.currentState!.pushNamed('b'));
        await tester.pump();
        expect(env.getBox(tester).size, const Size(100, 200));
        await tester.pump(const Duration(milliseconds: 150));
        expect(env.getBox(tester).size, const Size(150, 250));

        // Pop b in the middle of the transition.
        env.navigatorKey.currentState!.pop();
        await tester.pump();
        expect(env.getBox(tester).size, const Size(150, 250));
        await tester.pump(const Duration(milliseconds: 30));
        expect(env.getBox(tester).size, const Size(140, 240));
        await tester.pump(const Duration(milliseconds: 30));
        expect(env.getBox(tester).size, const Size(130, 230));
        await tester.pump(const Duration(milliseconds: 30));
        expect(env.getBox(tester).size, const Size(120, 220));
        await tester.pump(const Duration(milliseconds: 30));
        expect(env.getBox(tester).size, const Size(110, 210));
        await tester.pumpAndSettle();
        expect(env.getBox(tester).size, const Size(100, 200));
      },
    );

    testWidgets('When replacing the current route', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();
      unawaited(env.navigatorKey.currentState!.pushReplacementNamed('c'));
      expect(env.getBox(tester).size, const Size(200, 300));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(200, 300),
          const Size(150, 250),
          Curves.easeInOut.transform(progress),
        )!;
      }

      // Not sure why, but without this pump, the animation gets stuck at
      // value=0.0 even when we advance the clock 75ms in the subsequent pump.
      await tester.pump(Duration.zero);

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(150, 250));
    });

    testWidgets('When replacing a route with Navigator.replace',
        (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      unawaited(env.navigatorKey.currentState!.pushNamed('b'));
      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(200, 300));

      final routeB = env.navigatorKey.currentState!.currentRoute;
      final navigator = env.navigatorKey.currentState!;
      final newRoute = ResizableMaterialPageRoute(
        settings: const RouteSettings(name: 'c'),
        builder: (_) => const _TestRouteWidget(initialSize: Size(150, 250)),
      );
      navigator.replace(oldRoute: routeB, newRoute: newRoute);
      await tester.pump();
      expect(env.getBox(tester).size, const Size(150, 250));
    });
  });

  group('iOS swipe back gesture test with imperative navigator API', () {
    ({
      GlobalKey<NavigatorState> navigatorKey,
      RenderBox Function(WidgetTester) getBox,
      Widget testWidget,
    }) boilerplate() {
      final navigatorKey = GlobalKey<NavigatorState>();
      final navigatorResizableKey = UniqueKey();
      final routes = {
        'a': () => const _TestRouteWidget(initialSize: Size(100, 200)),
        'b': () => const _TestRouteWidget(initialSize: Size(200, 300)),
      };
      final testWidget = MaterialApp(
        home: Align(
          alignment: Alignment.center,
          child: NavigatorResizable(
            key: navigatorResizableKey,
            child: Navigator(
              key: navigatorKey,
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

      RenderBox getBox(WidgetTester tester) {
        return tester.renderObject(find.byKey(navigatorResizableKey));
      }

      return (
        navigatorKey: navigatorKey,
        getBox: getBox,
        testWidget: testWidget,
      );
    }

    testWidgets(
      'When iOS swipe back gesture is performed',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);

        unawaited(env.navigatorKey.currentState!.pushNamed('b'));
        await tester.pumpAndSettle();

        final transitionProgress =
            env.navigatorKey.currentState!.currentRoute.animation!;

        // Start the swipe back gesture.
        // We assume that the screen size is 800x600.
        final gesture = await tester.startGesture(const Offset(300, 300));
        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(env.navigatorKey.currentState!.userGestureInProgress, isTrue);
        expect(transitionProgress.value, moreOrLessEquals(0.9));
        expect(env.getBox(tester).size, const Size(190, 290));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.8));
        expect(env.getBox(tester).size, const Size(180, 280));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.7));
        expect(env.getBox(tester).size, const Size(170, 270));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.6));
        expect(env.getBox(tester).size, const Size(160, 260));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.5));
        expect(env.getBox(tester).size, const Size(150, 250));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.4));
        expect(env.getBox(tester).size, const Size(140, 240));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(env.navigatorKey.currentState!.userGestureInProgress, isFalse);
        expect(env.getBox(tester).size, const Size(100, 200));
      },
    );

    testWidgets(
      'When iOS swipe back gesture is canceled',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);

        unawaited(env.navigatorKey.currentState!.pushNamed('b'));
        await tester.pumpAndSettle();

        final transitionProgress =
            env.navigatorKey.currentState!.currentRoute.animation!;

        // Start the swipe back gesture.
        // We assume that the screen size is 800x600.
        final gesture = await tester.startGesture(const Offset(300, 300));
        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(env.navigatorKey.currentState!.userGestureInProgress, isTrue);
        expect(transitionProgress.value, moreOrLessEquals(0.9));
        expect(env.getBox(tester).size, const Size(190, 290));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(env.navigatorKey.currentState!.userGestureInProgress, isFalse);
        expect(env.getBox(tester).size, const Size(200, 300));
      },
    );
  });

  group('Size transition test with declarative navigator API', () {
    ({
      GlobalKey<NavigatorState> navigatorKey,
      RenderBox Function(WidgetTester) getBox,
      ValueSetter<String> setLocation,
      Widget testWidget,
    }) boilerplate({
      String initialLocation = '/a',
      Curve interpolationCurve = Curves.easeInOut,
    }) {
      const pageA = ResizablePageRoutePageBuilder(
        name: 'a',
        key: ValueKey('a'),
        transitionDuration: Duration(milliseconds: 300),
        transitionsBuilder: _testTransitionsBuilder,
        child: _TestRouteWidget(initialSize: Size(100, 200)),
      );
      const pageB = ResizablePageRoutePageBuilder(
        name: 'b',
        key: ValueKey('b'),
        transitionDuration: Duration(milliseconds: 300),
        transitionsBuilder: _testTransitionsBuilder,
        child: _TestRouteWidget(initialSize: Size(200, 300)),
      );
      const pageC = ResizablePageRoutePageBuilder(
        name: 'c',
        key: ValueKey('c'),
        transitionDuration: Duration(milliseconds: 300),
        transitionsBuilder: _testTransitionsBuilder,
        child: _TestRouteWidget(initialSize: Size.infinite),
      );
      const pageD = ResizablePageRoutePageBuilder(
        name: 'd',
        key: ValueKey('d'),
        transitionDuration: Duration(milliseconds: 300),
        transitionsBuilder: _testTransitionsBuilder,
        child: _TestRouteWidget(initialSize: Size(300, 400)),
      );

      final navigatorKey = GlobalKey<NavigatorState>();
      final navigatorResizableKey = UniqueKey();

      var location = initialLocation;
      late StateSetter setStateFn;
      void setLocation(String newLocation) {
        location = newLocation;
        setStateFn(() {});
      }

      RenderBox getBox(WidgetTester tester) {
        return tester.renderObject(find.byKey(navigatorResizableKey));
      }

      final testWidget = MaterialApp(
        home: Center(
          child: NavigatorResizable(
            key: navigatorResizableKey,
            interpolationCurve: interpolationCurve,
            child: StatefulBuilder(
              builder: (_, setState) {
                setStateFn = setState;

                return Navigator(
                  key: navigatorKey,
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

      return (
        navigatorKey: navigatorKey,
        getBox: getBox,
        setLocation: setLocation,
        testWidget: testWidget,
      );
    }

    testWidgets('After initial build', (tester) async {
      final env = boilerplate();
      await tester.pumpWidget(env.testWidget);
      expect(env.getBox(tester).size, const Size(100, 200));
    });

    testWidgets('After initial build with multiple routes', (tester) async {
      final env = boilerplate(initialLocation: '/a/b/c');
      await tester.pumpWidget(env.testWidget);
      expect(env.getBox(tester).size, const Size(800, 600));
    });

    testWidgets('When pushing a new route', (tester) async {
      final env = boilerplate(interpolationCurve: Curves.easeInOut);
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/a/b');
      await tester.pump();
      expect(env.getBox(tester).size, const Size(100, 200));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(100, 200),
          const Size(200, 300),
          Curves.easeInOut.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(200, 300));
    });

    testWidgets('When pushing multiple routes simultaneously', (tester) async {
      final env = boilerplate(interpolationCurve: Curves.easeInOut);
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/a/b/c');
      await tester.pump();
      expect(env.getBox(tester).size, const Size(100, 200));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(100, 200),
          // The size of the page C should be the same as the screen size.
          const Size(800, 600),
          Curves.easeInOut.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(800, 600));
    });

    testWidgets(
      'When pushing a route and reverting in mid-transition',
      (tester) async {
        final env = boilerplate(interpolationCurve: Curves.linear);
        await tester.pumpWidget(env.testWidget);

        // Navigate to /a/b.
        env.setLocation('/a/b');
        await tester.pump();
        expect(env.getBox(tester).size, const Size(100, 200));
        await tester.pump(const Duration(milliseconds: 150));
        expect(env.getBox(tester).size, const Size(150, 250));

        // In the middle of the transition, return to /a.
        env.setLocation('/a');
        await tester.pump();
        expect(env.getBox(tester).size, const Size(150, 250));
        await tester.pump(const Duration(milliseconds: 30));
        expect(env.getBox(tester).size, const Size(140, 240));
        await tester.pump(const Duration(milliseconds: 30));
        expect(env.getBox(tester).size, const Size(130, 230));
        await tester.pump(const Duration(milliseconds: 30));
        expect(env.getBox(tester).size, const Size(120, 220));
        await tester.pump(const Duration(milliseconds: 30));
        expect(env.getBox(tester).size, const Size(110, 210));
        await tester.pumpAndSettle();
        expect(env.getBox(tester).size, const Size(100, 200));
      },
    );

    testWidgets('When popping a route', (tester) async {
      final env = boilerplate(interpolationCurve: Curves.easeInOut);
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/a/b');
      await tester.pumpAndSettle();
      env.setLocation('/a');
      await tester.pump();
      expect(env.getBox(tester).size, const Size(200, 300));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(200, 300),
          const Size(100, 200),
          Curves.easeInOut.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(100, 200));
    });

    testWidgets('When popping multiple routes simultaneously', (tester) async {
      final env = boilerplate(interpolationCurve: Curves.easeInOut);
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/a/b/c');
      await tester.pumpAndSettle();
      env.setLocation('/a');
      await tester.pump();
      expect(
        env.getBox(tester).size,
        const Size(800, 600),
        reason: 'The size of the page C should be the same as the screen size.',
      );

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(800, 600),
          const Size(100, 200),
          Curves.easeInOut.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(100, 200));
    });

    testWidgets('When replacing the entire page stack', (tester) async {
      final env = boilerplate(interpolationCurve: Curves.easeInOut);
      await tester.pumpWidget(env.testWidget);
      env.setLocation('/d');
      await tester.pump();
      expect(env.getBox(tester).size, const Size(100, 200));

      Size interpolatedSize(double progress) {
        return Size.lerp(
          const Size(100, 200),
          const Size(300, 400),
          Curves.easeInOut.transform(progress),
        )!;
      }

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.25));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.5));

      await tester.pump(const Duration(milliseconds: 75));
      expect(env.getBox(tester).size, interpolatedSize(0.75));

      await tester.pumpAndSettle();
      expect(env.getBox(tester).size, const Size(300, 400));
    });

    testWidgets(
      'When replacing the entire page stack and reverting in mid-transition',
      (tester) async {
        final env = boilerplate(
          initialLocation: '/a/b',
          interpolationCurve: Curves.linear,
        );
        await tester.pumpWidget(env.testWidget);

        // Replace the page stack with /d.
        env.setLocation('/d');
        await tester.pump();
        expect(env.getBox(tester).size, const Size(200, 300));
        await tester.pump(const Duration(milliseconds: 150));
        expect(env.getBox(tester).size, const Size(250, 350));

        // In the middle of the transition, return to /a/b.
        env.setLocation('/a/b');
        await tester.pump();
        expect(env.getBox(tester).size, const Size(250, 350));
        await tester.pump(const Duration(milliseconds: 60));
        expect(env.getBox(tester).size, const Size(240, 340));
        await tester.pump(const Duration(milliseconds: 60));
        expect(env.getBox(tester).size, const Size(230, 330));
        await tester.pump(const Duration(milliseconds: 60));
        expect(env.getBox(tester).size, const Size(220, 320));
        await tester.pump(const Duration(milliseconds: 60));
        expect(env.getBox(tester).size, const Size(210, 310));
        await tester.pumpAndSettle();
        expect(env.getBox(tester).size, const Size(200, 300));
      },
    );
  });

  group('iOS swipe back gesture test with declarative navigator API', () {
    ({
      GlobalKey<NavigatorState> navigatorKey,
      RenderBox Function(WidgetTester) getBox,
      ValueSetter<String> setLocation,
      Widget testWidget,
    }) boilerplate() {
      final navigatorKey = GlobalKey<NavigatorState>();
      final navigatorResizableKey = UniqueKey();
      const pageA = ResizableMaterialPage(
        name: 'a',
        key: ValueKey('a'),
        child: _TestRouteWidget(initialSize: Size(100, 200)),
      );
      const pageB = ResizableMaterialPage(
        name: 'b',
        key: ValueKey('b'),
        child: _TestRouteWidget(initialSize: Size(200, 300)),
      );

      var location = '/a';
      late StateSetter setStateFn;
      void setLocation(String newLocation) {
        location = newLocation;
        setStateFn(() {});
      }

      RenderBox getBox(WidgetTester tester) {
        return tester.renderObject(find.byKey(navigatorResizableKey));
      }

      final testWidget = MaterialApp(
        home: Center(
          child: NavigatorResizable(
            key: navigatorResizableKey,
            child: StatefulBuilder(
              builder: (_, setState) {
                setStateFn = setState;
                return Navigator(
                  key: navigatorKey,
                  onDidRemovePage: (page) {},
                  pages: switch (location) {
                    '/a' => [pageA],
                    '/a/b' => [pageA, pageB],
                    _ => throw StateError('Unknown location: $location'),
                  },
                );
              },
            ),
          ),
        ),
      );

      return (
        navigatorKey: navigatorKey,
        getBox: getBox,
        setLocation: setLocation,
        testWidget: testWidget,
      );
    }

    testWidgets(
      'When iOS swipe back gesture is performed',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);

        env.setLocation('/a/b');
        await tester.pumpAndSettle();

        final transitionProgress =
            env.navigatorKey.currentState!.currentRoute.animation!;

        // Start the swipe back gesture.
        // We assume that the screen size is 800x600.
        final gesture = await tester.startGesture(const Offset(300, 300));
        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(env.navigatorKey.currentState!.userGestureInProgress, isTrue);
        expect(transitionProgress.value, moreOrLessEquals(0.9));
        expect(env.getBox(tester).size, const Size(190, 290));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.8));
        expect(env.getBox(tester).size, const Size(180, 280));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.7));
        expect(env.getBox(tester).size, const Size(170, 270));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.6));
        expect(env.getBox(tester).size, const Size(160, 260));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.5));
        expect(env.getBox(tester).size, const Size(150, 250));

        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(transitionProgress.value, moreOrLessEquals(0.4));
        expect(env.getBox(tester).size, const Size(140, 240));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(env.navigatorKey.currentState!.userGestureInProgress, isFalse);
        expect(env.getBox(tester).size, const Size(100, 200));
      },
    );

    testWidgets(
      'When iOS swipe back gesture is canceled',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = boilerplate();
        await tester.pumpWidget(env.testWidget);

        env.setLocation('/a/b');
        await tester.pumpAndSettle();

        final transitionProgress =
            env.navigatorKey.currentState!.currentRoute.animation!;

        // Start the swipe back gesture.
        // We assume that the screen size is 800x600.
        final gesture = await tester.startGesture(const Offset(300, 300));
        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(env.navigatorKey.currentState!.userGestureInProgress, isTrue);
        expect(transitionProgress.value, moreOrLessEquals(0.9));
        expect(env.getBox(tester).size, const Size(190, 290));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(env.navigatorKey.currentState!.userGestureInProgress, isFalse);
        expect(env.getBox(tester).size, const Size(200, 300));
      },
    );
  });

  group('Layout test', () {
    ({
      ValueGetter<Size> getBoxSize,
      ValueSetter<Size> setContentSize,
      Widget testWidget,
    }) boilerplate({
      Size initialContentSize = const Size(100, 200),
      Widget Function(Widget)? builder,
    }) {
      final navigatorResizableKey = GlobalKey();
      final routeContentKey = GlobalKey<_TestRouteWidgetState>();

      Size getBoxSize() {
        return (navigatorResizableKey.currentContext!.findRenderObject()!
                as RenderBox)
            .size;
      }

      void setContentSize(Size size) {
        routeContentKey.currentState!.size = size;
      }

      final navigatorResizable = NavigatorResizable(
        key: navigatorResizableKey,
        child: Navigator(
          onGenerateInitialRoutes: (navigator, initialRoute) {
            return [
              ResizablePageRouteBuilder(
                settings: const RouteSettings(name: 'a'),
                pageBuilder: (_, __, ___) => _TestRouteWidget(
                  key: routeContentKey,
                  initialSize: initialContentSize,
                ),
                transitionsBuilder: _testTransitionsBuilder,
              ),
            ];
          },
        ),
      );

      final testWidget = MaterialApp(
        home: switch (builder) {
          null => Center(
              child: navigatorResizable,
            ),
          final builder => builder(navigatorResizable),
        },
      );

      return (
        getBoxSize: getBoxSize,
        setContentSize: setContentSize,
        testWidget: testWidget,
      );
    }

    testWidgets(
      'When the content size of the current route changes',
      (tester) async {
        final env = boilerplate(initialContentSize: const Size(100, 200));
        await tester.pumpWidget(env.testWidget);
        expect(env.getBoxSize(), const Size(100, 200));

        // Make it bigger.
        env.setContentSize(const Size(200, 300));
        // It *intentionally* takes two frames to update the size because:
        // in the first frame, the route content size is updated,
        // but we can't mark the render object of the NavigatorResizable
        // as dirty in the layout phase of the same frame. Instead,
        // we have to schedule the next frame to reflect the new content size
        // to the size of the NavigatorResizable.
        await tester.pump();
        expect(env.getBoxSize(), const Size(100, 200));
        await tester.pump();
        expect(env.getBoxSize(), const Size(200, 300));

        // Make it smaller.
        env.setContentSize(const Size(50, 100));
        await tester.pump();
        expect(env.getBoxSize(), const Size(200, 300));
        await tester.pump();
        expect(env.getBoxSize(), const Size(50, 100));
      },
    );

    testWidgets(
      'Route content is constrained by the parent constraints',
      (tester) async {
        final env = boilerplate(initialContentSize: Size.infinite);
        await tester.pumpWidget(env.testWidget);
        // Full screen size.
        expect(env.getBoxSize(), const Size(800, 600));
      },
    );

    testWidgets(
      'Throws assertion error when given tight constraint',
      (tester) async {
        final env = boilerplate(
          builder: (child) => ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 600,
              maxWidth: 800,
            ),
            child: child,
          ),
        );
        final exceptions = <Object>[];
        final oldErrorHandler = FlutterError.onError;
        FlutterError.onError = (details) => exceptions.add(details.exception);
        await tester.pumpWidget(env.testWidget);
        FlutterError.onError = oldErrorHandler;

        expect(
          exceptions.firstOrNull,
          isAssertionError.having(
            (it) => it.message,
            'message',
            'The NavigatorResizable widget was given an tight constraint. '
                'This is not allowed because it needs to size itself '
                'to fit the current route content. Consider wrapping '
                'the NavigatorResizable with a widget that provides non-tight '
                'constraints, such as Align and Center. \n'
                'The given constraints were: BoxConstraints(w=800.0, h=600.0) '
                'which was given by the parent: RenderConstrainedBox',
          ),
        );
      },
    );

    testWidgets(
      'Throws assertion error when given unbounded constraint',
      (tester) async {
        final env = boilerplate(
          builder: (child) => Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [child],
          ),
        );
        final exceptions = <Object>[];
        final oldErrorHandler = FlutterError.onError;
        FlutterError.onError = (details) => exceptions.add(details.exception);
        await tester.pumpWidget(env.testWidget);
        FlutterError.onError = oldErrorHandler;

        expect(
          exceptions.firstOrNull,
          isAssertionError.having(
            (it) => it.message,
            'message',
            'The NavigatorResizable widget was given unbounded constraints. '
                'This is not allowed because otherwise the routes within the '
                'underlying Navigator would not know their valid maximum size. '
                'This becomes especially problematic when a route specifies '
                'double.infinity for width or height to expand to '
                'the available space, which causes a layout error since '
                'the parent Navigator does not provide finite bounds.\n'
                'Make sure that NavigatorResizable is not wrapped in a widget '
                'that passes unbounded constraints to its children, such as '
                'Column or Row. The given constraints were:\n'
                'BoxConstraints(0.0<=w<=800.0, 0.0<=h<=Infinity) '
                '(from parent: RenderFlex).',
          ),
        );
      },
    );
  });

  group('Hit testing', () {
    late bool isRouteContentTapped;
    late bool isBackgroundTapped;
    late Widget testWidget;

    setUp(() {
      isRouteContentTapped = false;
      isBackgroundTapped = false;

      testWidget = MaterialApp(
        home: GestureDetector(
          onTap: () => isBackgroundTapped = true,
          child: ColoredBox(
            // A non-transparent background is required to detect taps.
            color: Colors.white,
            child: Center(
              child: NavigatorResizable(
                child: Navigator(
                  onGenerateRoute: (settings) {
                    return ResizablePageRouteBuilder(
                      settings: settings,
                      transitionsBuilder: _testTransitionsBuilder,
                      pageBuilder: (_, __, ___) => GestureDetector(
                        onTap: () => isRouteContentTapped = true,
                        child: const _TestRouteWidget(
                          initialSize: Size(200, 200),
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
}

class _TestRouteWidget extends StatefulWidget {
  const _TestRouteWidget({
    super.key,
    required this.initialSize,
  });

  final Size initialSize;

  @override
  State<_TestRouteWidget> createState() => _TestRouteWidgetState();
}

class _TestRouteWidgetState extends State<_TestRouteWidget> {
  late Size _size;
  Size get size => _size;
  set size(Size value) {
    setState(() => _size = value);
  }

  @override
  void initState() {
    super.initState();
    _size = widget.initialSize;
  }

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

Widget _testTransitionsBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}
