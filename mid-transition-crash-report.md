# Mid-transition navigation crash — diagnosis

**Status:** fixed in 3.0.4.
**Affected:** `lib/src/navigator_event_observer.dart` (`NavigatorEventObserverState`).
**Environment:** Flutter 3.47.0, `navigator_resizable` 3.0.3, branch `fix-mid-transition-issue`.

## Summary

`NavigatorEventObserver` throws in debug builds when the page stack is changed
faster than the route transitions can settle:

```
'package:navigator_resizable/src/navigator_event_observer.dart':
Failed assertion: line 285 pos 12: 'route.isCurrent': is not true.
```

The assertion escapes through `Route.didChangeNext`, which the navigator
dispatches while `NavigatorState._debugLocked` is set and **without** a
`finally`. The flag is therefore never cleared, so every subsequent frame and
every subsequent navigation throws `!_debugLocked` and the nested navigator
stays broken for the rest of the session.

The bug is in `NavigatorEventObserver` itself. It reproduces with a bare
`NavigatorEventObserver` wrapped around a plain `Navigator`; `NavigatorResizable`
is not involved.

## Root cause

`_didChangeNext` (`lib/src/navigator_event_observer.dart:322`) infers "a route
was popped off the top of me" from *my next route became `null`*:

```dart
void _didChangeNext(Route<dynamic> route, Route<dynamic>? nextRoute) {
  final didPopNext = nextRoute == null && _nextRouteOf.containsKey(route);
  _nextRouteOf[route] = nextRoute;
  _notifyListeners((it) => it.didChangeNext(route, nextRoute));
  if (didPopNext) {
    assert(_lastSettledRoute != null);
    _didPopNextInternal(route, _lastSettledRoute!);   // asserts route.isCurrent
  }
}
```

That inference only holds for a route that is still **active**. A route that has
already been popped stays in `NavigatorState._history` until its exit transition
finishes, and during that window it is a zombie: `isActive == false`,
`isCurrent == false`, and it will never become current again. If a newer route
is pushed above the zombie and then popped, the zombie's next route goes back to
`null`, `didPopNext` is inferred, and `_didPopNextInternal` trips its
`assert(route.isCurrent)` at line 285.

The minimum shape is three stack changes landing before the first has settled:

1. push `X`
2. pop `X` — `X` starts animating out but stays in the history
3. push `Y` above the still-popping `X` — sets `_nextRouteOf[X] = Y`
4. pop `Y` — fires `X.didChangeNext(null)` → boom

## Reproduction

Regression coverage lives in the two main test files — event-level assertions in
`test/navigator_event_observer_test.dart` and size-level assertions in
`test/navigator_resizable_test.dart`, one test per navigator API in each:

```
fvm flutter test --name "faster than the transitions settle"
fvm flutter test --name "not finished entering"
```

`example/lib/rapid_navigation_example.dart` reproduces both defects by hand: all
three pages carry their button at the same screen position, so tapping that one
spot repeatedly walks the stack A -> B -> C -> A without ever letting a
transition finish. Its transitions run for one second, which leaves a wide
margin for a human finger.

The original standalone reproduction is kept in
`test/mid_transition_regression_test.dart`. Before the fix, its two tests had to
be run one at a time (`--name`): once the first bricked its navigator, the leaked
`PerformanceModeRequestHandle` and undisposed `AnimationController`s contaminated
every later test in the same file. That contamination disappears with the fix.

### Declarative API

Page stack toggled `/a/b/c` → `/a` → `/a/b/c` → `/a`, pumping 100/16/16/16 ms
between hops. Event trace from the observer at the moment of the crash:

```
--- go(/a)                                                    # 4th hop
didComplete   c₂(cur=false, act=false, reverse:0.04)
didPop        c₂
didPopNext    a (cur=true) next=c₂
  >>didStartTransition a
didChangeNext c₁(cur=false, act=false, reverse:0.15) next=null   # <-- zombie
!!! assert(route.isCurrent) — navigator_event_observer.dart:285
```

`c₁` is the route popped by hop 2, still reversing. Hop 3 pushed `c₂` above it;
hop 4 popped `c₂`, resetting `c₁`'s next route to `null`.

### Imperative API

`pushNamed('b')` → `pop()` → `pushNamed('c')` → `pop()`, same 100/16/16/16 ms
pacing. Identical mechanism:

```
--- pop                                                       # 4th operation
didPop        c#245(cur=false, act=false, reverse:0.05)
didPopNext    a#649(cur=true) next=c#245
  >>didStartTransition a#649
didChangeNext b#770(cur=false, act=false, reverse:0.26) next=null   # <-- zombie
!!! assert(route.isCurrent) — navigator_event_observer.dart:285
```

One behavioural difference worth noting: with the imperative API the assertion
propagates **synchronously out of `Navigator.pop()`**, i.e. into the caller's
own code (a button's `onPressed`). With the declarative API `_updatePages` runs
during build, so the error is reported through `FlutterError.onError` instead.

### How wide is the window

Exhaustive sweeps over four-operation sequences × four pump durations
(16/100/200/299 ms), each group run in isolation:

| Sequence | API | Failing timing combinations |
| --- | --- | --- |
| `/a/b/c` → `/a` → `/a/b/c` → `/a` | declarative | 50 / 256 |
| `push b` → `pop` → `push c` | imperative | 0 / 64 |
| `push b` → `pop` → `push c` → `pop` | imperative | 103 / 256 |
| `push b` → `pop` → `push b` → `pop` | imperative | 103 / 256 |

All two- and three-hop sequences pass, which matches the analysis: the fourth
operation is what resets the zombie's next route back to `null`. At 20–40 % of
timing combinations this is a wide window, not a knife-edge race — consistent
with the issue being hit by ordinary quick taps.

## Why one throw bricks the navigator

`didChangeNext` is dispatched from `NavigatorState._flushHistoryUpdates`, called
by `_updatePages` (Flutter `navigator.dart:4438-4446`):

```dart
assert(() { _debugLocked = true;  return true; }());
_flushHistoryUpdates();
assert(() { _debugLocked = false; return true; }());
```

There is no `try`/`finally`, so an exception escaping `_flushHistoryUpdates`
skips the reset. `_debugLocked` stays `true` for the lifetime of the
`NavigatorState`, and after that:

- `NavigatorState.build` throws `assert(!_debugLocked)` (`navigator.dart:5949`)
  on every frame;
- `NavigatorState.dispose` throws the same (`navigator.dart:4128`);
- the half-torn-down element tree produces follow-on
  `_dependents.isEmpty` (`framework.dart:6281`) and undisposed
  `AnimationController` assertions.

Those cascading errors are all secondary; there is a single root defect.

## Release-build behaviour

With assertions stripped the code does not crash — it silently misbehaves.
Execution falls through into `_didPopNextInternal(zombie, _lastSettledRoute)`
where `poppedRoute` is the genuinely current route, whose animation status is
`completed` rather than `dismissed`. So the observer:

- notifies `didStartTransition(zombie, _TransitionProgress(currentRoute))`,
  i.e. announces a transition toward a route that is already gone, and
- registers a status listener waiting for `AnimationStatus.dismissed` on an
  animation that is sitting at `completed` and will never dismiss.

Result: a leaked status listener plus `NavigatorResizable` sizing itself against
the wrong route. Worth fixing on its own merits, independent of the assertion.

## A second defect in the same code path

`example/lib/rapid_navigation_example.dart` — written to reproduce the crash
above — surfaced a second, independent bug in `_didChangeNext`, which fires the
*other* assertion in `_didPopNextInternal`:

```
Failed assertion: line 293 pos 12:
'poppedRoute.animation!.status == AnimationStatus.reverse': is not true.
```

The inferred-pop path passed `_lastSettledRoute` as the route whose exit
transition drives the transition back to `route`. That is only a proxy, and it
holds solely when the route that just went away had already settled. Walking the
page stack `/a` -> `/a/b` -> `/a/b/c` -> `/a` without letting any transition
settle breaks it: neither `b` nor `c` ever settles, so `_lastSettledRoute` is
still `a` — the destination route itself — and its animation sits at `completed`
rather than `reverse`.

Event trace at the moment of the crash (`c` popped, `b` removed in the same
frame):

```
didComplete   c(cur=false,act=false,reverse:0.53)
didPop        c
didComplete   b(cur=true,act=true,forward:0.93)
didPopNext    b next=c
didChangeNext a(cur=true,act=true,completed:1.00) next=null
              oldNext=b  didPopNext=true  lastSettled=a   <-- a, not an exiting route
!!! assert(poppedRoute.animation!.status == AnimationStatus.reverse)
```

Unlike the first defect, this one needs no zombie route and no rapid tapping in
the strict sense: with the example's one-second transitions it reproduces at tap
intervals as long as 990 ms — roughly one tap per second.

## Fix

Two changes in `_didChangeNext`, both in `lib/src/navigator_event_observer.dart`.

**1. Guard the inferred pop.** It is now a guard rather than a downstream
assertion, so it only fires for a route that is genuinely live and on top:

```dart
final didPopNext =
    nextRoute == null && _nextRouteOf.containsKey(route) && route.isCurrent;
```

`isCurrent` already implies `isActive` (`navigator.dart:584-595` — it matches the
last history entry satisfying `isPresentPredicate`), so no separate `isActive`
check is needed. This makes `_didPopNextInternal`'s precondition locally
guaranteed instead of merely asserted; its `assert(route.isCurrent)` stays as a
real invariant for the `_didPopNext` (genuine `Route.didPopNext`) caller.

**2. Find the exiting route instead of guessing it.** `_lastSettledRoute` is
replaced by a walk up the `_nextRouteOf` chain, which the observer already
maintains, to find the top-most route above `route` that is actually running its
exit transition:

```dart
Route<dynamic>? exitingRoute;
if (didPopNext) {
  for (
    var above = _nextRouteOf[route];
    above != null;
    above = _nextRouteOf[above]
  ) {
    if (above is TransitionRoute<dynamic> &&
        above.animation!.status == AnimationStatus.reverse) {
      exitingRoute = above;
    }
  }
}
```

`_didPopNextInternal`'s second parameter is now nullable: `null` means nothing is
animating above `route`, so the transition is already over and
`didEndTransition` fires immediately. In the one pre-existing scenario that used
this path (popping a settled `/a/b/c` down to `/a`), the walk finds exactly the
route `_lastSettledRoute` used to point at, so nothing changes there.

One consequence worth noting: when two pops overlap, two transitions toward the
same destination route are started, so that route receives two matching
`didEndTransition` calls. That is consistent with the documented contract
(`didEndTransition` is called once per transition) and is asserted by the new
tests.

## Baseline

Before the fix: 77 passing, and all eight new regression tests failing. After the
fix: 87 passing, `dart analyze` clean of new issues, and
`example/lib/rapid_navigation_example.dart` surviving 20 consecutive taps at
every interval from 0 ms to 990 ms (8 of those 10 intervals throw on the
unfixed code).
