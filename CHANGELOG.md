# Changelog

## X.X.X

- Fix: assertion error when popping route in the middle of transition animation ([#16](https://github.com/fujidaiti/navigator_resizable/issues/16))
- `NavigatorResizable` now asserts when provided with unbounded width or height constraints([#12](https://github.com/fujidaiti/navigator_resizable/issues/12)).

### Breaking change in `NavigatorResizable`

`NavigatorResizable` now requires bounded constraints on both axes. If its parent passes unbounded constraints (e.g., from `Column` or `Row`), an assertion will be thrown in debug mode. This helps catch cases where routes inside the underlying `Navigator` might otherwise receive infinite dimensions, which often surface when route content uses `double.infinity` for width/height to expand and fill the available space.

### Breaking change in `NavigatorEventListener`

The signature of `NavigatorEventListener.didStartTransition` has been changed to handle edge cases where a transition is started in the middle of another transition, for example, when a route is pushed and immediately popped.

**BEFORE**

Previously, the route that is placed on top of the navigation stack before the transition starts is passed as the first argument of `didStartTransition`.

```dart
void didStartTransition(
  Route<dynamic> currentRoute,
  Route<dynamic> nextRoute,
  Animation<double> animation, {
  bool isUserGestureInProgress = false,
});
```

**AFTER**

In the new signature, the first argument `currentRoute` was removed, and the second argument was renamed to `targetRoute`. You can still keep track of the top-most route by capturing the `route` object reported by the `NavigatorEventObserver.didEndTransition` callback.

```dart
void didStartTransition(
  Route<dynamic> targetRoute,
  Animation<double> animation, {
  bool isUserGestureInProgress = false,
});
```

## 2.0.0

- Updated minimum supported Flutter SDK to `3.29.0`.
- The invocation order of `NavigatorEventListener` callbacks has been changed to align with the behavior of the latest Flutter SDK.

### Background

Flutter `3.29.0` introduced changes to the sequence of underlying navigator events, which may affect the invocation order of `NavigatorEventListener` callbacks.

### Breaking changes in `NavigatorEventObserver`

The sequence in which `NavigatorEventObserver` invokes its `NavigatorEventListener` callback methods has been adjusted to align with the updated Flutter SDK. These changes do not affect the behavior of the `NavigatorResizable` widget itself.

#### Zero-Duration Pop Transitions

Zero-duration pop transitions occur when a route is popped with no animation duration (i.e., `transitionDuration: Duration.zero`), causing the transition to complete instantly without any visual animation. Previously, the `didEndTransition(routeBelow)` callback was invoked immediately after the `didPopNext(routeBelow, poppedRoute)` callback. Now, the `didStartTransition(poppedRoute, routeBelow, ...)` callback is invoked after `didPopNext(...)`, and the `didEndTransition(routeBelow)` callback is invoked later after the transition has settled.

#### Declarative Multi-Route Pushes

Previously, when pushing multiple routes via a single state change (e.g., navigating from `/A` to `/A/B/C`), the `didInstall(B)` callback for intermediate routes was invoked early in the sequence alongside the primary transition events for route `C`. Now, the `didInstall(B)` callback for intermediate routes is invoked later in the sequence, after the primary transition has completed (i.e., after `didEndTransition(C)`).

## 1.0.2

- Rename the `ResizablePageBuilder` to `ResizablePageRoutePageBuilder`, and the `ResizablePageRoutePageBuilder` to `ResizablePageRouteBuilder`.

## 1.0.1

- Fix broken links in the README.

## 1.0.0

- Initial release.
