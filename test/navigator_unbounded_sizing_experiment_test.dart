// Experiments to verify a hypothesis for fixing the one-frame delay issue
// described in navigator_resizable_test.dart ("When the content size of
// the current route changes"):
//
// Claim: A Navigator sizes itself to fit the current route's top-level
// widget when given unbounded (infinite) width and height constraints,
// and it does so within the SAME layout pass in which the route content's
// size changes (i.e. no one-frame delay at the Navigator <-> route boundary).
//
// These tests are exploratory and not meant to be kept as part of the
// permanent test suite.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigator_resizable/src/navigator_resizable.dart';
import 'package:navigator_resizable/src/resizable_navigator_routes.dart';

void main() {
  RenderBox boxOf(GlobalKey key) {
    return key.currentContext!.findRenderObject()! as RenderBox;
  }

  testWidgets(
    'Navigator shrink-wraps to the current route content '
    'when given unbounded constraints',
    (tester) async {
      final navigatorKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: UnconstrainedBox(
              child: Navigator(
                key: navigatorKey,
                onGenerateInitialRoutes: (navigator, initialRoute) {
                  return [
                    PageRouteBuilder<void>(
                      pageBuilder: (_, _, _) => Container(
                        color: Colors.white,
                        width: 200,
                        height: 100,
                      ),
                    ),
                  ];
                },
              ),
            ),
          ),
        ),
      );

      expect(boxOf(navigatorKey).size, const Size(200, 100));
    },
  );

  testWidgets(
    'Navigator relayouts synchronously (no one-frame delay) when the '
    'current route content size changes, given unbounded constraints',
    (tester) async {
      final navigatorKey = GlobalKey();
      final contentKey = GlobalKey<_ResizableContentState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: UnconstrainedBox(
              child: Navigator(
                key: navigatorKey,
                onGenerateInitialRoutes: (navigator, initialRoute) {
                  return [
                    PageRouteBuilder<void>(
                      pageBuilder: (_, _, _) => _ResizableContent(
                        key: contentKey,
                        initialSize: const Size(100, 200),
                      ),
                    ),
                  ];
                },
              ),
            ),
          ),
        ),
      );

      expect(boxOf(navigatorKey).size, const Size(100, 200));

      contentKey.currentState!.size = const Size(300, 400);
      await tester.pump();
      // If this passes with a SINGLE pump, the Navigator picks up the new
      // content size in the same frame the content changes size - unlike
      // NavigatorResizable today, which requires two pumps (see
      // navigator_resizable_test.dart).
      expect(boxOf(navigatorKey).size, const Size(300, 400));
    },
  );

  testWidgets(
    'Navigator only shrink-wraps on axes that are unbounded; '
    'bounded axes fill to the given max',
    (tester) async {
      final navigatorKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              // Bounded width (800), unbounded height.
              constraints: const BoxConstraints(maxWidth: 800),
              child: UnconstrainedBox(
                constrainedAxis: Axis.horizontal,
                alignment: Alignment.topLeft,
                child: Navigator(
                  key: navigatorKey,
                  onGenerateInitialRoutes: (navigator, initialRoute) {
                    return [
                      PageRouteBuilder<void>(
                        pageBuilder: (_, _, _) => Container(
                          color: Colors.white,
                          width: double.infinity,
                          height: 150,
                        ),
                      ),
                    ];
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(boxOf(navigatorKey).size, const Size(800, 150));
    },
  );

  testWidgets(
    'Navigator size during a push transition: top-route-only vs union, '
    'using non-dominating sizes (a=500x100, b=100x400) to disambiguate',
    (tester) async {
      final navigatorKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: UnconstrainedBox(
              child: Navigator(
                key: navigatorKey,
                onGenerateInitialRoutes: (navigator, initialRoute) {
                  return [
                    PageRouteBuilder<void>(
                      settings: const RouteSettings(name: 'a'),
                      transitionDuration: const Duration(milliseconds: 200),
                      reverseTransitionDuration:
                          const Duration(milliseconds: 200),
                      pageBuilder: (_, _, _) => Container(
                        color: Colors.white,
                        width: 500,
                        height: 100,
                      ),
                    ),
                  ];
                },
              ),
            ),
          ),
        ),
      );

      final navigator = navigatorKey.currentState! as NavigatorState;
      expect(boxOf(navigatorKey).size, const Size(500, 100));

      navigator.push(
        PageRouteBuilder<void>(
          settings: const RouteSettings(name: 'b'),
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, _, _) => Container(
            color: Colors.blue,
            width: 100,
            height: 400,
          ),
        ),
      );

      await tester.pump();
      // ignore: avoid_print
      print('t=0ms navigator size: ${boxOf(navigatorKey).size}');
      // If this is (100,400) -> sizes to the top (incoming) route only.
      // If this is (500,400) -> sizes to the union of onstage routes.
      // If this is (500,100) -> still driven by the outgoing route.

      await tester.pump(const Duration(milliseconds: 100));
      // ignore: avoid_print
      print('t=100ms navigator size: ${boxOf(navigatorKey).size}');

      await tester.pump(const Duration(milliseconds: 200));
      // ignore: avoid_print
      print('t=300ms (settled) navigator size: ${boxOf(navigatorKey).size}');
      expect(boxOf(navigatorKey).size, const Size(100, 400));
    },
  );

  testWidgets(
    'Navigator size with a route stack (no transition in progress) is '
    'driven only by the topmost route, ignoring routes underneath',
    (tester) async {
      final navigatorKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: UnconstrainedBox(
              child: Navigator(
                key: navigatorKey,
                onGenerateInitialRoutes: (navigator, initialRoute) {
                  return [
                    PageRouteBuilder<void>(
                      settings: const RouteSettings(name: 'a'),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, _, _) => Container(
                        color: Colors.white,
                        width: 500,
                        height: 500,
                      ),
                    ),
                    PageRouteBuilder<void>(
                      settings: const RouteSettings(name: 'b'),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, _, _) => Container(
                        color: Colors.blue,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ];
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(boxOf(navigatorKey).size, const Size(100, 100));
    },
  );

  testWidgets(
    'When does the raw (unbounded) Navigator size switch to the '
    'destination route during an iOS swipe-back gesture?',
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    (tester) async {
      final navigatorKey = GlobalKey();
      Route<void>? routeB;
      final routes = {
        'a': () => const _ResizableTestRouteWidget(size: Size(100, 200)),
        'b': () => const _ResizableTestRouteWidget(size: Size(200, 300)),
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            child: NavigatorResizable(
              child: Navigator(
                key: navigatorKey,
                initialRoute: 'a',
                onGenerateRoute: (settings) {
                  final route = ResizableMaterialPageRoute<void>(
                    settings: settings,
                    builder: (_) => routes[settings.name]!(),
                  );
                  if (settings.name == 'b') {
                    routeB = route;
                  }
                  return route;
                },
              ),
            ),
          ),
        ),
      );

      final navigator = navigatorKey.currentState! as NavigatorState;
      navigator.pushNamed('b');
      await tester.pumpAndSettle();
      expect(boxOf(navigatorKey).size, const Size(200, 300));

      final routeAnimation = (routeB! as TransitionRoute<void>).animation!;
      routeAnimation.addStatusListener((status) {
        // ignore: avoid_print
        print(
          '  [route b animation status changed: $status, '
          'value=${routeAnimation.value}]',
        );
      });

      // Drag just a little, so the gesture-driven progress doesn't get
      // clamped to 0 by the distorted (shrunk) context.size denominator --
      // that would make the release-to-settle animation trivially short
      // and defeat the purpose of watching it frame-by-frame.
      final gesture = await tester.startGesture(const Offset(300, 300));
      await gesture.moveBy(const Offset(130, 0));
      await tester.pump();
      // ignore: avoid_print
      print(
        'after small drag: raw Navigator size = ${boxOf(navigatorKey).size}, '
        'route b animation value = ${routeAnimation.value}',
      );

      await gesture.up();
      // ignore: avoid_print
      print(
        'right after gesture.up(), before pumping: '
        'raw Navigator size = ${boxOf(navigatorKey).size}, '
        'userGestureInProgress = ${navigator.userGestureInProgress}, '
        'route b animation value = ${routeAnimation.value}',
      );

      var elapsed = Duration.zero;
      for (var i = 0; i < 40; i++) {
        const step = Duration(milliseconds: 16);
        await tester.pump(step);
        elapsed += step;
        // ignore: avoid_print
        print(
          '+${elapsed.inMilliseconds}ms: raw Navigator size = '
          '${boxOf(navigatorKey).size}, '
          'route b animation value = ${routeAnimation.value}',
        );
      }

      await tester.pumpAndSettle();
      // ignore: avoid_print
      print(
        'after pumpAndSettle(): '
        'raw Navigator size = ${boxOf(navigatorKey).size}',
      );
      expect(boxOf(navigatorKey).size, const Size(100, 200));
    },
  );
}

class _ResizableTestRouteWidget extends StatelessWidget {
  const _ResizableTestRouteWidget({required this.size});

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

class _ResizableContent extends StatefulWidget {
  const _ResizableContent({super.key, required this.initialSize});

  final Size initialSize;

  @override
  State<_ResizableContent> createState() => _ResizableContentState();
}

class _ResizableContentState extends State<_ResizableContent> {
  late Size _size = widget.initialSize;

  Size get size => _size;
  set size(Size value) => setState(() => _size = value);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: size.width,
      height: size.height,
    );
  }
}
