// A measurement harness (not an assertion test).
//
// It records the observable state of standard Flutter routes
// (MaterialPageRoute / MaterialPage, with no package-specific mixin)
// frame by frame during the navigation scenarios covered by
// navigator_event_observer_test.dart, and writes the result to
// `route_state_probe_report.md` at the package root.
//
// Run with: fvm flutter test test/route_state_probe_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'src/widget_tester_x.dart';

const String _findings = r"""
## Findings

### 1. `Route.isCurrent` identifies the transition destination

In every scenario, the route that the transition moves *toward* has
`isCurrent == true` for the whole duration of the transition, and the route
being left behind has `isCurrent == false`. This is the direct replacement for
the `targetRoute` argument of `NavigatorEventListener.didStartTransition`.

Timing of the flip differs between the two APIs:

- Imperative: `isCurrent` flips synchronously inside the `Navigator.push` /
  `pop` / `pushReplacement` call, before the next frame (see the
  `before pump` rows).
- Declarative: `isCurrent` flips during the build phase of the next frame
  (see the `frame 1 (t=0)` rows, where the observer callbacks also appear).

The one exception is a user gesture. While an iOS swipe back or an Android
predictive back gesture is in progress, `isCurrent` stays on the top route and
only moves to the previous route when the gesture is committed.

### 2. The transition progress is fully described by the current route's two animations

For the current route `R`:

- `R.animation` describes `R` entering (push, replacement, gesture cancel).
- `R.secondaryAnimation` describes the route directly above `R` leaving
  (pop, gesture commit). It is the same animation object chain as the exiting
  route's `animation`, so the values match frame by frame.

A transition can therefore be detected without an observer as:

    final busy = R.animation.isAnimating || R.secondaryAnimation.isAnimating;

and it ends when both become non-animating. This matches
`didStartTransition` / `didEndTransition` in all of the simple scenarios
(push, pop, push/pop without animation, pushReplacement, `Navigator.replace`,
mid-transition reverts, and both gestures on both platforms).

### 3. Known gap: declarative multi-pop detaches `secondaryAnimation` too early

In `/a/b/c -> /a` (declarative), page `b` is removed instantly with no
transition while page `c` runs its 300 ms exit animation. From frame 1 on,
`a.secondaryAnimation` already reads `0.00 / dismissed`, so rule 2 reports the
transition as finished while `c` is still visibly animating out. The same
happens in the `pop multiple pages during a push transition` edge case.

The imperative equivalent does not have this problem: `Navigator.pop()` called
twice keeps `b` in the stack until its animation ends, so
`a.secondaryAnimation` tracks the exit correctly.

Consequently, the exiting route cannot always be reached from the current
route. It has to be obtained from `NavigatorObserver.didPop` / `didRemove`,
which report `c` and `b` at frame 1.

### 4. `offstage` is not observable at a frame boundary

`ModalRoute.offstage` is `true` only in the window between the navigation
request and the first frame. It is visible in the imperative `before pump`
rows and never at `frame 1 (t=0)`; with the declarative API it is not
observable from outside at all, because the route is created and taken
offstage within a single build.

While offstage, `TransitionRoute.animation` (a `ProxyAnimation`) reads
`1.00 / completed` even though `controller.value` is `0.00`. Code that reads
`route.animation.value` synchronously right after `Navigator.push` therefore
gets `1.0`. This is the discontinuity that `_TransitionProgress` in
`navigator_event_observer.dart` currently works around. Reading the value one
frame later, or reading `controller.value`, avoids it.

### 5. `NavigatorObserver.didChangeTop` is a usable "transition started" signal

`didChangeTop(topRoute, previousTopRoute)` fires exactly once per change of
the top-most route in every scenario measured: push, pop, multi-push,
multi-pop, `pushReplacement`, `Navigator.replace`, declarative page list
changes, and gesture commit. It does not fire on gesture cancel, which is the
correct behavior. Combined with rule 2 it covers what
`didStartTransition` / `didEndTransition` provide today, and it works with
standard route classes because `NavigatorObserver` is attached to the
`Navigator`, not to the routes.

Ordering caveat: with the declarative API the callbacks arrive during the
build phase, so a listener must not call `setState` synchronously from them.

### 6. `isActive` separates "in the stack" from "exiting"

- `isActive && isCurrent` - the destination route.
- `isActive && !isCurrent` - a route below the top.
- `!isActive` - the route has been popped or removed and is only running its
  exit animation. Its `animation` keeps reversing until `dismissed`.

An exiting route is disposed as soon as its animation reaches `dismissed`
(the `disposed` rows). Any reference held to such a route must be
dropped at that point.

### 7. Gestures

`NavigatorState.userGestureInProgress` together with
`didStartUserGesture` / `didStopUserGesture` covers both the iOS swipe back
and the Android predictive back gesture, on standard routes.

- During the gesture, the top route's `animation` follows the gesture
  progress and `isCurrent` does not move.
- On commit, `didPop` and `didChangeTop` fire and `isCurrent` moves to the
  previous route.
- On cancel, no `didPop` / `didChangeTop` fires and the animation returns
  to `1.00`.
- `didStopUserGesture` fires only after the animation settles, not when the
  finger is lifted.

One defect carries over to standard routes: with
`PredictiveBackFullscreenPageTransitionsBuilder`, committing the Android
gesture makes the exiting route's `animation` jump from its gesture value
(`0.40`) back to `1.00` before reversing. This is the same discontinuity that
`_AnimationLessAndroidBackGestureHandler` in `resizable_navigator_routes.dart`
works around, so a size transition driven by these animations still needs a
workaround for that case.

### 8. Issue #57: animation status is not a transition boundary during a gesture

Measured in the two `issue #57` scenarios. During an iOS swipe back gesture,
`_CupertinoBackGestureController.dragUpdate` writes `controller.value`
directly on every pointer move, so the animation reaches its end states purely
because of the finger position:

- Dragging to the right edge (x=800) makes the top route's animation
  `0.00 / dismissed`.
- Dragging back to x=0 makes it `1.00 / completed`.

In both cases `userGestureInProgress` is still `true`, the top route still has
`isCurrent == true` and `isActive == true`, and no `didPop` or `didChangeTop`
has fired. The stack has not changed at all. This is exactly the condition
that trips `assert(destinationRoute.isCurrent)` at
`navigator_event_observer.dart:456`, and that makes the `completed` branch
end the transition too early.

Two consequences for an observerless design:

1. The rule in finding 2 is not sufficient on its own. At x=800 neither
   `a.animation` nor `a.secondaryAnimation` is animating, yet the transition is
   not over. A transition must also be considered in progress whenever
   `NavigatorState.userGestureInProgress` is `true`.
2. `isCurrent` / `isActive` and the observer callbacks are the reliable
   boundary. They change only when the finger is lifted and the pop is actually
   performed in `_CupertinoBackGestureController.dragEnd`.

The timing of `didStopUserGesture` also differs between the two scenarios:

- Full-width drag: the route is already at progress 0.0 when the finger is
  lifted, so `didPop`, `didChangeTop` and `didStopUserGesture` all fire in the
  same frame and no exit animation runs.
- Partial drag: `didPop` and `didChangeTop` fire when the finger is lifted, and
  `didStopUserGesture` fires later, after the exit animation settles.

A listener must therefore not assume that `didStopUserGesture` always arrives
after the exit animation, nor that an exit animation always runs.

### 9. Page identity: a matching `Page.key` reuses the same `Route`

Measured in the two "Swap the middle pages" scenarios, which change
`/a/b/c` into `/a/x/y/c`.

When the top page keeps the same `Page.key` and runtime type, the `Navigator`
reuses the **same `Route` instance**. Its `isCurrent`, `isActive` and
`animation` (`1.00 / completed`) never change, no `didPush`, `didPop` or
`didChangeTop` is reported for it, and no transition runs at all. Only the
pages below it change: `x` and `y` are pushed straight to `completed` with no
animation, and `b` is removed and disposed in the same frame. For
`NavigatorResizable` this means the navigator size must stay exactly where it
is; there is nothing to animate.

When the top page's key differs (`/a/b/c -> /a/x/y/c2`), a second `Route` is
created and an ordinary push transition runs from `c` to `c2`.

That contrast exposes a second behavior worth recording. In the differing-key
case the observer reports `didPush(x)`, `didPush(y)` and `didPush(c2)` all in
frame 1, but `x` and `y` are **not installed** for the whole 300 ms of the
transition: `route.navigator` is null and `route.animation` is null, because
`Route.install()` is what assigns the navigator and creates the animation. They
are only installed once the exiting route finishes and is disposed (the
`pushed, not installed` rows). The `Navigator` defers installing routes that
are inserted below a route that is still animating out.

Two consequences:

- A design that reacts to `didPush` must not assume the route has an
  animation yet. This affects Idea 1 in `observerless_architecture_design.md`.
- A design that discovers routes from their mounted content is unaffected,
  because an uninstalled route has no content in the overlay and is invisible.
  It simply starts being tracked when it is installed.

### 10. Summary

An observerless architecture appears feasible using only
`NavigatorObserver.didChangeTop` / `didPop` / `didRemove` /
`didStartUserGesture` / `didStopUserGesture`, plus `Route.isCurrent`,
`Route.isActive`, `NavigatorState.userGestureInProgress` and the two
animations of the current route. Three problems remain to be solved:

1. The declarative multi-pop case (finding 3), where the exiting route must
   come from the observer rather than from `secondaryAnimation`.
2. Gesture-driven transitions (finding 8), where animation status must be
   ignored as an end-of-transition signal while `userGestureInProgress` is
   true. Note that this also fixes issue #57.
3. The Android predictive back animation jump (finding 7), which is a Flutter
   framework behavior and not caused by the observer design.
""";

final StringBuffer _report = StringBuffer();

// ---------------------------------------------------------------------------
// Recording infrastructure
// ---------------------------------------------------------------------------

/// A plain [NavigatorObserver]. It works with any standard route, so it is
/// available in an observerless (no ObservableRouteMixin) architecture.
class _Probe extends NavigatorObserver {
  final List<Route<dynamic>> known = <Route<dynamic>>[];
  final Map<Route<dynamic>, String> ids = <Route<dynamic>, String>{};
  final Map<String, int> _nameCount = <String, int>{};
  final List<String> pending = <String>[];

  String id(Route<dynamic>? route) {
    if (route == null) return 'null';
    return ids[route] ?? _register(route);
  }

  String _register(Route<dynamic> route) {
    final name = switch (route.settings) {
      final Page<dynamic> p => p.name ?? '?',
      final RouteSettings s => s.name ?? '?',
    };
    final n = (_nameCount[name] ?? 0) + 1;
    _nameCount[name] = n;
    final id = n == 1 ? name : '$name#$n';
    ids[route] = id;
    known.add(route);
    return id;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pending.add('didPush(${id(route)}, prev=${id(previousRoute)})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pending.add('didPop(${id(route)}, prev=${id(previousRoute)})');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pending.add('didRemove(${id(route)}, prev=${id(previousRoute)})');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    pending.add('didReplace(new=${id(newRoute)}, old=${id(oldRoute)})');
  }

  @override
  void didChangeTop(
    Route<dynamic> topRoute,
    Route<dynamic>? previousTopRoute,
  ) {
    pending.add('didChangeTop(${id(topRoute)}, prev=${id(previousTopRoute)})');
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    pending.add('didStartUserGesture(${id(route)}, prev=${id(previousRoute)})');
  }

  @override
  void didStopUserGesture() {
    pending.add('didStopUserGesture()');
  }
}

class _Snap {
  _Snap({
    required this.step,
    required this.events,
    required this.rows,
    required this.userGesture,
  });

  final String step;
  final String events;
  final List<List<String>> rows;
  final bool userGesture;
}

class _Recorder {
  _Recorder(this.probe, this.title, this.notes);

  final _Probe probe;
  final String title;
  final String notes;
  final List<_Snap> snaps = <_Snap>[];

  static String _s(AnimationStatus? s) => switch (s) {
    AnimationStatus.forward => 'fwd',
    AnimationStatus.reverse => 'rev',
    AnimationStatus.completed => 'done',
    AnimationStatus.dismissed => 'dism',
    null => '-',
  };

  static String _v(double? v) => v == null ? '-' : v.toStringAsFixed(2);

  static String _b(bool? v) => switch (v) {
    true => 'Y',
    false => '.',
    null => '?',
  };

  final Set<Route<dynamic>> _everInstalled = <Route<dynamic>>{};

  void snap(String step) {
    final events = probe.pending.join('<br>');
    probe.pending.clear();

    final rows = <List<String>>[];
    for (final route in probe.known) {
      final id = probe.ids[route]!;
      if (route.navigator != null) {
        _everInstalled.add(route);
      } else {
        // A route that has been announced by the observer but whose navigator
        // is still null has not been installed yet: Route.install() is what
        // assigns the navigator and creates the animation. A route that had a
        // navigator before and does not now has been disposed.
        rows.add([
          id,
          _everInstalled.contains(route) ? 'disposed' : 'pushed, not installed',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
        ]);
        continue;
      }
      final modal = route is ModalRoute ? route : null;
      final transition = route as TransitionRoute<dynamic>;
      final anim = transition.animation;
      final sec = transition.secondaryAnimation;
      // ignore: invalid_use_of_protected_member
      final controller = transition.controller;
      rows.add([
        id,
        _b(route.isCurrent),
        _b(route.isActive),
        _b(route.isFirst),
        _b(modal?.offstage),
        _v(anim?.value),
        _s(anim?.status),
        _v(sec?.value),
        _s(sec?.status),
        _v(controller?.value),
      ]);
    }

    snaps.add(
      _Snap(
        step: step,
        events: events,
        rows: rows,
        userGesture: probe.navigator?.userGestureInProgress ?? false,
      ),
    );
  }

  void flush() {
    _report
      ..writeln('### $title')
      ..writeln();
    if (notes.isNotEmpty) {
      _report
        ..writeln(notes)
        ..writeln();
    }
    _report
      ..writeln(
        '| step | observer events | route | cur | act | 1st | offstage | '
        'anim | animStatus | sec | secStatus | ctrl | gesture |',
      )
      ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | '
        '--- | --- | --- |',
      );
    for (final snap in snaps) {
      var first = true;
      if (snap.rows.isEmpty) {
        _report.writeln(
          '| ${snap.step} | ${snap.events} | (no routes) | | | | | | | | '
          '| | |',
        );
      }
      for (final row in snap.rows) {
        final step = first ? snap.step : '';
        final events = first ? snap.events : '';
        final gesture = first ? (snap.userGesture ? 'Y' : '.') : '';
        first = false;
        final padded = [...row, ...List.filled(10 - row.length, '')];
        _report.writeln(
          '| $step | $events | ${padded.join(' | ')} | $gesture |',
        );
      }
    }
    _report.writeln();
  }
}

// ---------------------------------------------------------------------------
// Standard (non package-specific) route plumbing
// ---------------------------------------------------------------------------

/// A plain [MaterialPageRoute] with a configurable transition duration.
/// No `ObservableRouteMixin` is applied.
class _TestMaterialPageRoute extends MaterialPageRoute<dynamic> {
  _TestMaterialPageRoute({
    required super.builder,
    super.settings,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionsBuilder,
  });

  @override
  final Duration transitionDuration;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  final PageTransitionsBuilder? transitionsBuilder;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return switch (transitionsBuilder) {
      null => super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      ),
      final builder => builder.buildTransitions(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      ),
    };
  }
}

/// A plain [MaterialPage]-like page. `MaterialPage` itself cannot expose a
/// custom transition duration, so the route is re-declared here using only
/// public Flutter API (`PageRoute` + `MaterialRouteTransitionMixin`).
class _TestMaterialPage extends Page<dynamic> {
  const _TestMaterialPage({
    super.key,
    super.name,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionsBuilder,
    required this.child,
  });

  final Duration transitionDuration;
  final PageTransitionsBuilder? transitionsBuilder;
  final Widget child;

  @override
  Route<dynamic> createRoute(BuildContext context) =>
      _TestPageBasedRoute(page: this);
}

class _TestPageBasedRoute extends PageRoute<dynamic>
    with MaterialRouteTransitionMixin<dynamic> {
  _TestPageBasedRoute({required _TestMaterialPage page})
    : super(settings: page);

  _TestMaterialPage get _page => settings as _TestMaterialPage;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page.transitionDuration;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return switch (_page.transitionsBuilder) {
      null => super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      ),
      final builder => builder.buildTransitions(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      ),
    };
  }
}

class _TestScaffold extends StatelessWidget {
  const _TestScaffold({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}

// ---------------------------------------------------------------------------
// Scenarios
// ---------------------------------------------------------------------------

typedef _ImperativeEnv = ({
  Widget testWidget,
  GlobalKey<NavigatorState> navigatorKey,
  _Probe probe,
});

_ImperativeEnv _imperativeBoilerplate({
  Duration transitionDuration = const Duration(milliseconds: 300),
  PageTransitionsBuilder? transitionsBuilder,
}) {
  final navigatorKey = GlobalKey<NavigatorState>();
  final probe = _Probe();
  final testWidget = MaterialApp(
    navigatorKey: navigatorKey,
    navigatorObservers: [probe],
    initialRoute: 'a',
    onGenerateRoute: (settings) => _TestMaterialPageRoute(
      settings: settings,
      transitionDuration: transitionDuration,
      transitionsBuilder: transitionsBuilder,
      builder: (_) => _TestScaffold(title: 'Page:${settings.name}'),
    ),
  );
  return (testWidget: testWidget, navigatorKey: navigatorKey, probe: probe);
}

typedef _DeclarativeEnv = ({
  Widget testWidget,
  ValueSetter<String> setLocation,
  _Probe probe,
});

_DeclarativeEnv _declarativeBoilerplate({
  String initialLocation = '/a',
  Duration transitionDuration = const Duration(milliseconds: 300),
  PageTransitionsBuilder? transitionsBuilder,
}) {
  _TestMaterialPage page(String name) => _TestMaterialPage(
    key: ValueKey(name),
    name: name,
    transitionDuration: transitionDuration,
    transitionsBuilder: transitionsBuilder,
    child: _TestScaffold(title: 'Page:$name'),
  );

  final pageA = page('a');
  final pageB = page('b');
  final pageC = page('c');
  final pageD = page('d');
  final pageX = page('x');
  final pageY = page('y');
  final pageC2 = page('c2');

  var location = initialLocation;
  late VoidCallback invokeSetState;
  void setLocation(String newLocation) {
    location = newLocation;
    invokeSetState();
  }

  final probe = _Probe();
  final testWidget = MaterialApp(
    home: StatefulBuilder(
      builder: (_, setState) {
        invokeSetState = () => setState(() {});
        return Navigator(
          observers: [probe],
          onDidRemovePage: (page) {},
          pages: switch (location) {
            '/a' => [pageA],
            '/a/b' => [pageA, pageB],
            '/a/b/c' => [pageA, pageB, pageC],
            '/a/x/y/c' => [pageA, pageX, pageY, pageC],
            '/a/x/y/c2' => [pageA, pageX, pageY, pageC2],
            '/d' => [pageD],
            _ => throw StateError('Unknown location: $location'),
          },
        );
      },
    ),
  );

  return (testWidget: testWidget, setLocation: setLocation, probe: probe);
}

/// Samples the state at the sub-frame boundary, the first frame (where the
/// entering route is built offstage), a few mid-transition frames, and after
/// the transition settles.
Future<void> _stepThrough(WidgetTester tester, _Recorder rec) async {
  rec.snap('before pump');
  await tester.pump();
  rec.snap('frame 1 (t=0)');
  await tester.pump(const Duration(milliseconds: 1));
  rec.snap('frame 2 (t=1ms)');
  await tester.pump(const Duration(milliseconds: 99));
  rec.snap('t=100ms');
  await tester.pump(const Duration(milliseconds: 100));
  rec.snap('t=200ms');
  await tester.pump(const Duration(milliseconds: 100));
  rec.snap('t=300ms');
  await tester.pumpAndSettle();
  rec.snap('settled');
}

void main() {
  tearDownAll(() {
    final header = StringBuffer()
      ..writeln('# Route state during transitions (observerless probe)')
      ..writeln()
      ..writeln(
        'Generated by `test/route_state_probe_test.dart` '
        '(Flutter 3.47.4).',
      )
      ..writeln()
      ..writeln(
        'All routes below are **standard** Flutter routes '
        '(`MaterialPageRoute` / a plain `PageRoute` + '
        '`MaterialRouteTransitionMixin`). No `ObservableRouteMixin` is '
        'applied. The only observation point is a plain `NavigatorObserver`.',
      )
      ..writeln()
      ..writeln('Column legend:')
      ..writeln()
      ..writeln(
        '- `cur` = `Route.isCurrent`, `act` = `Route.isActive`, '
        '`1st` = `Route.isFirst`',
      )
      ..writeln('- `offstage` = `ModalRoute.offstage`')
      ..writeln(
        '- `anim` / `animStatus` = `TransitionRoute.animation` '
        '(the proxy; reads 1.00/done while offstage)',
      )
      ..writeln('- `sec` / `secStatus` = `TransitionRoute.secondaryAnimation`')
      ..writeln(
        '- `ctrl` = `TransitionRoute.controller.value` '
        '(the raw controller behind the proxy)',
      )
      ..writeln('- `gesture` = `NavigatorState.userGestureInProgress`')
      ..writeln('- `Y` = true, `.` = false')
      ..writeln()
      ..writeln(_findings);
    File(
      'route_state_probe_report.md',
    ).writeAsStringSync('$header$_report');
  });

  group('imperative', () {
    setUpAll(() {
      _report.writeln('## Raw measurements: imperative API\n');
    });

    testWidgets('initial build', (tester) async {
      final env = _imperativeBoilerplate();
      final rec = _Recorder(env.probe, 'Initial build', '');
      await tester.pumpWidget(env.testWidget);
      rec.snap('after pumpWidget');
      await tester.pumpAndSettle();
      rec.snap('settled');
      rec.flush();
    });

    testWidgets('push a route', (tester) async {
      final env = _imperativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(env.probe, 'Push a route (a -> b)', '');
      env.navigatorKey.currentState!.pushNamed('b');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('push without animation', (tester) async {
      final env = _imperativeBoilerplate(transitionDuration: Duration.zero);
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Push a route without animation (transitionDuration: zero)',
        '',
      );
      env.navigatorKey.currentState!.pushNamed('b');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('push multiple simultaneously', (tester) async {
      final env = _imperativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Push multiple routes simultaneously (a -> b, c in one frame)',
        '',
      );
      env.navigatorKey.currentState!.pushNamed('b');
      env.navigatorKey.currentState!.pushNamed('c');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('pop a route', (tester) async {
      final env = _imperativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      env.navigatorKey.currentState!.pushNamed('b');
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(env.probe, 'Pop a route (b -> a)', '');
      env.navigatorKey.currentState!.pop();
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('pop without animation', (tester) async {
      final env = _imperativeBoilerplate(transitionDuration: Duration.zero);
      await tester.pumpWidget(env.testWidget);
      env.navigatorKey.currentState!.pushNamed('b');
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Pop a route without animation (transitionDuration: zero)',
        '',
      );
      env.navigatorKey.currentState!.pop();
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('pop multiple simultaneously', (tester) async {
      final env = _imperativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      env.navigatorKey.currentState!.pushNamed('b');
      await tester.pumpAndSettle();
      env.navigatorKey.currentState!.pushNamed('c');
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Pop multiple routes simultaneously (c, b popped in one frame)',
        '',
      );
      env.navigatorKey.currentState!
        ..pop()
        ..pop();
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('replace entire stack', (tester) async {
      final env = _imperativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Replace the entire stack (pushReplacementNamed: a -> b)',
        '',
      );
      env.navigatorKey.currentState!.pushReplacementNamed('b');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('Navigator.replace a non-root route', (tester) async {
      final env = _imperativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      env.navigatorKey.currentState!.pushNamed('b');
      await tester.pumpAndSettle();
      final routeB = ModalRoute.of(
        tester.element(find.text('Page:b')),
      )!;
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Replace a non-root route with Navigator.replace (b -> c)',
        'Note: `Navigator.replace` performs no transition animation.',
      );
      env.navigatorKey.currentState!.replace(
        oldRoute: routeB,
        newRoute: _TestMaterialPageRoute(
          settings: const RouteSettings(name: 'c'),
          builder: (_) => const _TestScaffold(title: 'Page:c'),
        ),
      );
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('push then revert mid-transition', (tester) async {
      final env = _imperativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Push to a sibling route, then pop back mid-transition',
        '',
      );
      env.navigatorKey.currentState!.pushNamed('b');
      await tester.pump();
      rec.snap('pushed b, frame 1');
      await tester.pump(const Duration(milliseconds: 150));
      rec.snap('t=150ms (mid push)');
      env.navigatorKey.currentState!.pop();
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('replace then revert mid-transition', (tester) async {
      final env = _imperativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'pushReplacement to d, then pushReplacement back to a '
            'mid-transition',
        '',
      );
      env.navigatorKey.currentState!.pushReplacementNamed('d');
      await tester.pump();
      rec.snap('replaced with d, frame 1');
      await tester.pump(const Duration(milliseconds: 150));
      rec.snap('t=150ms (mid transition)');
      env.navigatorKey.currentState!.pushReplacementNamed('a');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets(
      'iOS swipe back performed',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = _imperativeBoilerplate();
        await tester.pumpWidget(env.testWidget);
        env.navigatorKey.currentState!.pushNamed('b');
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'iOS swipe back gesture, committed',
          '',
        );
        final gesture = await tester.startGesture(const Offset(0, 200));
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();
        rec.snap('gesture started (+50px)');
        await gesture.moveBy(const Offset(150, 0));
        await tester.pump();
        rec.snap('dragged to +200px');
        await gesture.moveBy(const Offset(200, 0));
        await tester.pump();
        rec.snap('dragged to +400px');
        await gesture.up();
        await tester.pump();
        rec.snap('finger lifted, frame 1');
        await tester.pump(const Duration(milliseconds: 50));
        rec.snap('+50ms');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );

    testWidgets(
      'iOS swipe back canceled',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = _imperativeBoilerplate();
        await tester.pumpWidget(env.testWidget);
        env.navigatorKey.currentState!.pushNamed('b');
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'iOS swipe back gesture, canceled',
          '',
        );
        final gesture = await tester.startGesture(const Offset(0, 200));
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();
        rec.snap('gesture started (+50px)');
        await gesture.up();
        await tester.pump();
        rec.snap('finger lifted, frame 1');
        await tester.pump(const Duration(milliseconds: 50));
        rec.snap('+50ms');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );

    // Reproduces https://github.com/fujidaiti/navigator_resizable/issues/57
    testWidgets(
      'iOS swipe back dragged to the end without lifting the finger',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = _imperativeBoilerplate();
        await tester.pumpWidget(env.testWidget);
        env.navigatorKey.currentState!.pushNamed('b');
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'issue #57: iOS swipe back dragged across the full width, '
              'finger still down',
          'The navigator is 800px wide. The finger is dragged all the way to '
              'the right edge so that the transition progress reaches 0.0 '
              'while `userGestureInProgress` is still true.',
        );
        final gesture = await tester.startGesture(const Offset(0, 200));
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();
        rec.snap('x=50');
        await gesture.moveBy(const Offset(350, 0));
        await tester.pump();
        rec.snap('x=400 (halfway)');
        await gesture.moveBy(const Offset(400, 0));
        await tester.pump();
        rec.snap('x=800 (full width, finger down)');
        await tester.pump(const Duration(milliseconds: 16));
        rec.snap('+1 frame, finger still down');
        await gesture.up();
        await tester.pump();
        rec.snap('finger lifted, frame 1');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );

    // Reproduces https://github.com/fujidaiti/navigator_resizable/issues/57
    testWidgets(
      'iOS swipe back dragged to the end and back to the start '
      'without lifting the finger',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = _imperativeBoilerplate();
        await tester.pumpWidget(env.testWidget);
        env.navigatorKey.currentState!.pushNamed('b');
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'issue #57: iOS swipe back dragged to the end, back to the start, '
              'then forward again, finger still down',
          'The transition progress reaches both 0.0 (dismissed) and 1.0 '
              '(completed) while `userGestureInProgress` is still true.',
        );
        final gesture = await tester.startGesture(const Offset(0, 200));
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();
        rec.snap('x=50');
        await gesture.moveBy(const Offset(750, 0));
        await tester.pump();
        rec.snap('x=800 (full width, finger down)');
        await gesture.moveBy(const Offset(-800, 0));
        await tester.pump();
        rec.snap('back to x=0 (finger down)');
        await tester.pump(const Duration(milliseconds: 16));
        rec.snap('+1 frame, finger still down');
        await gesture.moveBy(const Offset(400, 0));
        await tester.pump();
        rec.snap('forward again to x=400 (finger down)');
        await gesture.up();
        await tester.pump();
        rec.snap('finger lifted, frame 1');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );

    testWidgets(
      'Android predictive back performed',
      variant: TargetPlatformVariant.only(TargetPlatform.android),
      (tester) async {
        final env = _imperativeBoilerplate(
          transitionsBuilder:
              const PredictiveBackFullscreenPageTransitionsBuilder(),
        );
        await tester.pumpWidget(env.testWidget);
        env.navigatorKey.currentState!.pushNamed('b');
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'Android predictive back gesture, committed',
          'Uses `PredictiveBackFullscreenPageTransitionsBuilder`.',
        );
        await tester.startAndroidBackGesture(touchOffset: [5.0, 300.0]);
        await tester.pump();
        rec.snap('gesture started');
        await tester.updateAndroidBackGestureProgress(
          x: 100,
          y: 300,
          progress: 0.3,
        );
        await tester.pump();
        rec.snap('progress 0.3');
        await tester.updateAndroidBackGestureProgress(
          x: 200,
          y: 300,
          progress: 0.6,
        );
        await tester.pump();
        rec.snap('progress 0.6');
        await tester.commitAndroidBackGesture();
        await tester.pump();
        rec.snap('committed, frame 1');
        await tester.pump(const Duration(milliseconds: 50));
        rec.snap('+50ms');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );

    testWidgets(
      'Android predictive back canceled',
      variant: TargetPlatformVariant.only(TargetPlatform.android),
      (tester) async {
        final env = _imperativeBoilerplate(
          transitionsBuilder:
              const PredictiveBackFullscreenPageTransitionsBuilder(),
        );
        await tester.pumpWidget(env.testWidget);
        env.navigatorKey.currentState!.pushNamed('b');
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'Android predictive back gesture, canceled',
          'Uses `PredictiveBackFullscreenPageTransitionsBuilder`.',
        );
        await tester.startAndroidBackGesture(touchOffset: [5.0, 300.0]);
        await tester.pump();
        rec.snap('gesture started');
        await tester.updateAndroidBackGestureProgress(
          x: 100,
          y: 300,
          progress: 0.3,
        );
        await tester.pump();
        rec.snap('progress 0.3');
        await tester.cancelAndroidBackGesture();
        await tester.pump();
        rec.snap('canceled, frame 1');
        await tester.pump(const Duration(milliseconds: 50));
        rec.snap('+50ms');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );
  });

  group('declarative', () {
    setUpAll(() {
      _report.writeln(
        '## Raw measurements: declarative API (Navigator.pages)\n',
      );
    });

    testWidgets('initial build', (tester) async {
      final env = _declarativeBoilerplate();
      final rec = _Recorder(env.probe, 'Initial build', '');
      await tester.pumpWidget(env.testWidget);
      rec.snap('after pumpWidget');
      await tester.pumpAndSettle();
      rec.snap('settled');
      rec.flush();
    });

    testWidgets('initial build with multiple routes', (tester) async {
      final env = _declarativeBoilerplate(initialLocation: '/a/b/c');
      final rec = _Recorder(
        env.probe,
        'Initial build with multiple pages ([a, b, c])',
        '',
      );
      await tester.pumpWidget(env.testWidget);
      rec.snap('after pumpWidget');
      await tester.pumpAndSettle();
      rec.snap('settled');
      rec.flush();
    });

    testWidgets('push a page', (tester) async {
      final env = _declarativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(env.probe, 'Push a page (/a -> /a/b)', '');
      env.setLocation('/a/b');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('push without animation', (tester) async {
      final env = _declarativeBoilerplate(transitionDuration: Duration.zero);
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Push a page without animation (transitionDuration: zero)',
        '',
      );
      env.setLocation('/a/b');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('push multiple pages simultaneously', (tester) async {
      final env = _declarativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Push multiple pages simultaneously (/a -> /a/b/c)',
        '',
      );
      env.setLocation('/a/b/c');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('replace the root page', (tester) async {
      final env = _declarativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Replace the root page (/a -> /d)',
        '',
      );
      env.setLocation('/d');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('pop a page', (tester) async {
      final env = _declarativeBoilerplate(initialLocation: '/a/b');
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(env.probe, 'Pop a page (/a/b -> /a)', '');
      env.setLocation('/a');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('pop without animation', (tester) async {
      final env = _declarativeBoilerplate(
        initialLocation: '/a/b',
        transitionDuration: Duration.zero,
      );
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Pop a page without animation (transitionDuration: zero)',
        '',
      );
      env.setLocation('/a');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('pop multiple pages simultaneously', (tester) async {
      final env = _declarativeBoilerplate(initialLocation: '/a/b/c');
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Pop multiple pages simultaneously (/a/b/c -> /a)',
        '',
      );
      env.setLocation('/a');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('swap middle pages, keep the top page key', (tester) async {
      final env = _declarativeBoilerplate(initialLocation: '/a/b/c');
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Swap the middle pages, keeping the top page key '
            '(/a/b/c -> /a/x/y/c)',
        'Page `c` keeps the same `ValueKey` across the update. '
            'A new id such as `c#2` in the route column would mean that a '
            'second `Route` was created for the same `Page`.',
      );
      env.setLocation('/a/x/y/c');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('swap middle pages and change the top page key', (
      tester,
    ) async {
      final env = _declarativeBoilerplate(initialLocation: '/a/b/c');
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Swap the middle pages and change the top page key '
            '(/a/b/c -> /a/x/y/c2)',
        'The contrast case for the scenario above: the top page has a '
            'different `ValueKey`, so it cannot be matched with the old one.',
      );
      env.setLocation('/a/x/y/c2');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('replace the entire page stack', (tester) async {
      final env = _declarativeBoilerplate(initialLocation: '/a/b');
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Replace the entire page stack (/a/b -> /d)',
        '',
      );
      env.setLocation('/d');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('push then revert mid-transition', (tester) async {
      final env = _declarativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Push a page, then revert mid-transition (/a -> /a/b -> /a)',
        '',
      );
      env.setLocation('/a/b');
      await tester.pump();
      rec.snap('pushed b, frame 1');
      await tester.pump(const Duration(milliseconds: 150));
      rec.snap('t=150ms (mid push)');
      env.setLocation('/a');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('replace root then revert mid-transition', (tester) async {
      final env = _declarativeBoilerplate();
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Replace the root page, then revert mid-transition '
            '(/a -> /d -> /a)',
        '',
      );
      env.setLocation('/d');
      await tester.pump();
      rec.snap('replaced with d, frame 1');
      await tester.pump(const Duration(milliseconds: 150));
      rec.snap('t=150ms (mid transition)');
      env.setLocation('/a');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets('pop multiple pages during a push transition', (tester) async {
      final env = _declarativeBoilerplate(initialLocation: '/a/b');
      await tester.pumpWidget(env.testWidget);
      await tester.pumpAndSettle();
      env.probe.pending.clear();

      final rec = _Recorder(
        env.probe,
        'Edge case: pop multiple pages during a push transition '
            '(/a/b -> /a/b/c -> /a)',
        '',
      );
      env.setLocation('/a/b/c');
      await tester.pump();
      rec.snap('pushed c, frame 1');
      await tester.pump(const Duration(milliseconds: 150));
      rec.snap('t=150ms (mid push)');
      env.setLocation('/a');
      await _stepThrough(tester, rec);
      rec.flush();
    });

    testWidgets(
      'iOS swipe back performed',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = _declarativeBoilerplate(initialLocation: '/a/b');
        await tester.pumpWidget(env.testWidget);
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'iOS swipe back gesture, committed',
          'Note: with the declarative API, the page list is not updated by '
              'the gesture in this harness (`onDidRemovePage` is a no-op).',
        );
        final gesture = await tester.startGesture(const Offset(0, 200));
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();
        rec.snap('gesture started (+50px)');
        await gesture.moveBy(const Offset(350, 0));
        await tester.pump();
        rec.snap('dragged to +400px');
        await gesture.up();
        await tester.pump();
        rec.snap('finger lifted, frame 1');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );

    testWidgets(
      'iOS swipe back canceled',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        final env = _declarativeBoilerplate(initialLocation: '/a/b');
        await tester.pumpWidget(env.testWidget);
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'iOS swipe back gesture, canceled',
          '',
        );
        final gesture = await tester.startGesture(const Offset(0, 200));
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();
        rec.snap('gesture started (+50px)');
        await gesture.up();
        await tester.pump();
        rec.snap('finger lifted, frame 1');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );

    testWidgets(
      'Android predictive back performed',
      variant: TargetPlatformVariant.only(TargetPlatform.android),
      (tester) async {
        final env = _declarativeBoilerplate(
          initialLocation: '/a/b',
          transitionsBuilder:
              const PredictiveBackFullscreenPageTransitionsBuilder(),
        );
        await tester.pumpWidget(env.testWidget);
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'Android predictive back gesture, committed',
          '',
        );
        await tester.startAndroidBackGesture(touchOffset: [5.0, 300.0]);
        await tester.pump();
        rec.snap('gesture started');
        await tester.updateAndroidBackGestureProgress(
          x: 100,
          y: 300,
          progress: 0.3,
        );
        await tester.pump();
        rec.snap('progress 0.3');
        await tester.commitAndroidBackGesture();
        await tester.pump();
        rec.snap('committed, frame 1');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );

    testWidgets(
      'Android predictive back canceled',
      variant: TargetPlatformVariant.only(TargetPlatform.android),
      (tester) async {
        final env = _declarativeBoilerplate(
          initialLocation: '/a/b',
          transitionsBuilder:
              const PredictiveBackFullscreenPageTransitionsBuilder(),
        );
        await tester.pumpWidget(env.testWidget);
        await tester.pumpAndSettle();
        env.probe.pending.clear();

        final rec = _Recorder(
          env.probe,
          'Android predictive back gesture, canceled',
          '',
        );
        await tester.startAndroidBackGesture(touchOffset: [5.0, 300.0]);
        await tester.pump();
        rec.snap('gesture started');
        await tester.updateAndroidBackGestureProgress(
          x: 100,
          y: 300,
          progress: 0.3,
        );
        await tester.pump();
        rec.snap('progress 0.3');
        await tester.cancelAndroidBackGesture();
        await tester.pump();
        rec.snap('canceled, frame 1');
        await tester.pumpAndSettle();
        rec.snap('settled');
        rec.flush();
      },
    );
  });
}
