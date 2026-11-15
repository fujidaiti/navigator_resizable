# Changelog

## 3.2.0-wip

- Migrate to [material_ui](https://pub.dev/packages/material_ui)
- Fix an assertion error when showing an `OverlayPortal`-based widget, such as `Tooltip`, from a route (#58)
-  Fix: `NavigatorResizable`'s size lags one frame behind when the current route's content changes size outside of a route transition (e.g., a route rebuilds at a taller height), which could cause a visible flicker in widgets whose layout depends on that size (#54)
- Fix: assertion error when the iOS swipe back gesture is dragged to the end without lifting the finger (#57)

The minimum required Flutter SDK version is now 3.50.0 (and Dart SDK to 3.14.0), which includes [a fix](https://github.com/flutter/flutter/pull/193079) for #58.

`BuildContext.size` for widgets below the `NavigatorResizable` now returns the intrinsic size of the navigator's current route. Previously, it returned the size of the parent render object for the `NavigatorResizable`, which was typically the screen size.

Also note that `ResizableMaterialPageRoute` and `ResizableMaterialPage` are now based on the Material widgets from material_ui instead of `package:flutter/material.dart`. If your app still uses `package:flutter/material.dart` from the SDK, you may encounter runtime errors due to incompatibilities between widgets from the two Material packages. Please follow [the material_ui migration guide](https://pub.dev/packages/material_ui#migrating-existing-code-to-this-package) to migrate your app.

## 3.1.0

- Bump minimum Flutter SDK version to 3.41.0 to avoid a mid-transition crash
- Fix: assertion error when popping multiple routes in the middle of a push transition

## 3.0.3

- Add missing `@mustCallSuper`s to ObservableRouteMixin

## 3.0.2

- Fix jaggy route pop animation with predictive back gesture on Android
- Fix assertion error after performing predictive back gesture on Android

## 3.0.1

- Add `key`, `name`, `arguments`, and `restorationId` parameters to `ResizablePageRoutePageBuilder`
- Fix: `NavigatorResizable` size doesn't update when the current route is changed via `Navigator.replace`
- Bump minimum Flutter SDK version to 3.35.1

## 3.0.0

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
