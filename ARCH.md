# Architecture

This document describes how `NavigatorResizable` determines its size. It is
intended for maintainers of this package.

## Overview

`NavigatorResizable` visually resizes a child `Navigator` to match the size of
the content of the current route. The only requirement imposed on the
application is that the content of each route is wrapped in
a `ResizableNavigatorRouteContentBoundary`. Any kind of route can be used,
including `MaterialPageRoute`, `PageRouteBuilder`, and the pages created by
routing packages such as go_router.

There is no route subclass, no route mixin, and no `NavigatorObserver`
involved. All the information needed to compute the size is obtained from
inside the route content:

| Required information                | Source                                                        |
| ----------------------------------- | ------------------------------------------------------------- |
| The size a route wants to be        | The layout of the child of the content boundary               |
| How far a route transition has come | `ModalRoute.of(context).animation` and `ModalRoute.offstage`   |
| The order of the routes             | The paint order of the content boundaries in the render tree   |

## Size model

The preferred size of the navigator is computed from the route contents,
ordered from the bottom-most route to the top-most one. Starting with the size
of the bottom-most route, the size of each route above it is interpolated in
turn, using that route's transition progress as the interpolation ratio:

```
size = lerp(lerp(sizeOfA, sizeOfB, progressOfB), sizeOfC, progressOfC)
```

where `progressOfX` is the value of the route's `animation`, which is 0 when
the route is completely hidden and 1 when it is fully presented.

Consequently:

- When no transition is in progress, every progress value is 1, and the result
  is the size of the top-most route content.
- When a route is pushed or popped, its progress moves between 0 and 1, and the
  size moves between the size of the route below it and its own size.
- The result is a pure function of the route content sizes, the transition
  progress values, and the order of the routes. No state has to be kept between
  transitions, and no route lifecycle event has to be observed.

The `NavigatorResizable.interpolationCurve` is applied to each progress value
before the interpolation, except while `NavigatorState.userGestureInProgress`
is true. During a swipe back gesture, the size follows the gesture exactly.

## Components

```
NavigatorResizable                 Owns NavigatorSizeNotifier and exposes it to
 └ _InheritedNavigatorResizable      the descendant content boundaries.
    └ _RenderNavigatorResizable     Computes the size of the navigator.
       └ Navigator (the child)
          └ Overlay
             └ route content
                └ _RenderRouteContentBoundary   One per route content.
                   └ the route content itself
```

- **`_RenderNavigatorResizable`** lays out the child navigator with the
  constraints it received itself, so the navigator can overflow this render
  box. It then collects the geometries of the route contents, asks
  `NavigatorSizeNotifier` to recompute the preferred size, and adopts that size.
  It also clips and restricts hit testing to that size.

- **`ResizableNavigatorRouteContentBoundary`** resolves the enclosing
  `ModalRoute` and the ancestor `NavigatorSizeNotifier`, listens to the route's
  transition animation, and reports the transition progress of the route. It
  also handles Android's predictive back gesture, described below.

- **`_RenderRouteContentBoundary`** aligns the route content to the top-left
  corner of the available space and records the size that the content chose.

- **`NavigatorSizeNotifier`** computes the preferred size from the collected
  geometries and notifies `_RenderNavigatorResizable` when the size has to be
  recomputed.

## Order of the routes

`_RenderNavigatorResizable` walks down its render subtree and collects the
`_RenderRouteContentBoundary`s in the order they are visited. This is the paint
order, which for the entries of the navigator's `Overlay` is always the same as
the order of the routes in the navigation stack. The walk does not descend into
a boundary that has been found, nor into a nested `_RenderNavigatorResizable`,
whose route contents belong to another navigator.

The walk is performed on every layout, after the child navigator has been laid
out. This guarantees that both the order and the content sizes are up to date,
including in the frame in which a route is added or removed.

## Recomputing the size

`NavigatorSizeNotifier` is a `Listenable` that `_RenderNavigatorResizable`
listens to in order to mark itself as needing layout. It is notified in two
ways, because the caller, not the notifier, knows whether a layout pass is in
progress:

- `invalidate()` marks the navigator as needing layout immediately. It is
  called when a content boundary is attached to or detached from the tree,
  which happens during the build phase, and on every tick of a route's
  transition animation.

- `invalidateAfterLayout()` schedules the invalidation for the next frame. It
  is called by `_RenderRouteContentBoundary` when the route content changes its
  size during layout, where it is too late to mark an ancestor render object as
  needing layout in the current frame.

Note that a route content can be laid out without `_RenderNavigatorResizable`
being laid out, because the render object of the `Overlay` is a relayout
boundary. This is why a content size change has to be reported explicitly.

## Transition progress details

- **The first frame of an entrance transition.** A route is built with
  `offstage = true` for one frame so that its content can be laid out before it
  is shown. While a route is offstage, `ModalRoute.animation` reports 1.0, so
  the progress is treated as 0 instead.

- **A route without a content boundary** is invisible to the
  `NavigatorResizable` and is skipped. The size therefore remains unchanged
  while such a route is the top-most route.

- **A route content that has not been laid out yet** has no size to report and
  is skipped as well. This happens, for example, to a route below an opaque
  route, since the `Overlay` does not lay out obscured entries.

## Android's predictive back gesture

`ResizableNavigatorRouteContentBoundary` registers itself as
a `WidgetsBindingObserver` and claims the back gesture when its route is the
current route and is not the first one. This is needed for two reasons.

First, `TransitionRoute.handleUpdateBackGestureProgress` decreases the
transition progress of the route as the gesture proceeds, but
`TransitionRoute.handleCommitBackGesture` restarts the pop transition from 1.0
regardless of the progress made during the gesture. Following the progress
would therefore cause an abrupt size change when the gesture is committed. To
avoid this, the reported progress is not allowed to go below the value at which
the gesture started, until the gesture is committed, or, if the gesture is
canceled, until the progress has animated back to that value.

Second, a route is popped by a predictive back gesture only if it is built with
a page transitions builder that supports the gesture, such as
`PredictiveBackPageTransitionsBuilder`. Such a builder registers its own
observer, which is notified before the one of the content boundary, since it is
an ancestor of it. The content boundary therefore checks whether the navigator
has already entered a user gesture, and pops the route by itself only if it
has not.

## Known characteristics

- **Simultaneous transitions pass through the intermediate routes.** If two
  routes are pushed in the same frame, the size is interpolated from the
  bottom-most route to the intermediate route, and then to the top-most one.
  The path can therefore slightly overshoot the size of the intermediate route.
  The size at the start and at the end of the transition is not affected.

- **Removing a hidden route during a transition changes the size the
  transition interpolates from.** For example, if the page stack `[a, b, c]` is
  replaced with `[a]` while `c` is being pushed, the page `b` is removed
  without a transition, and the size that the exit transition of `c`
  interpolates from changes from the size of `b` to the size of `a` at that
  moment. This is observed as a discontinuous size change. The size still
  settles to the size of `a`.
