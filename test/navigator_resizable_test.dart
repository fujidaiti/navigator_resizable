import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resizable_navigator/src/navigator_resizable.dart';
import 'package:resizable_navigator/src/resizable_navigator_routes.dart';
import 'package:resizable_navigator/src/route_transition_observer.dart';

void main() {
  late RouteTransitionObserver transitionObserver;

  setUp(() {
    transitionObserver = RouteTransitionObserver();
  });

  group('Size test with imperative navigator API', () {
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

    testWidgets('initial build', (tester) async {
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
