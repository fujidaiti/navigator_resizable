import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'navigator_event_observer.dart';
import 'navigator_resizable.dart';

const _defaultPreferredSize = Size.infinite;

@internal
class NavigatorSizeNotifier extends ChangeNotifier
    with NavigatorEventListener
    implements ValueListenable<Size> {
  NavigatorSizeNotifier({
    required this.interpolationCurve,
  });

  final _routeContentSizes = <Route<dynamic>, Size>{};
  final Curve interpolationCurve;
  Animation<Size?>? _interpolation;
  Route<dynamic>? _currentRoute;

  void _updateInterpolation(Animation<Size?>? newValue) {
    _interpolation?.removeListener(notifyListeners);
    _interpolation = newValue?..addListener(notifyListeners);
    if (newValue != null) {
      _currentRoute = null;
    }
  }

  void _updateCurrentRoute(Route<dynamic>? newRoute) {
    final oldSize = value;
    _currentRoute = newRoute;
    if (newRoute != null) {
      _updateInterpolation(null);
    }
    if (value != oldSize) {
      notifyListeners();
    }
  }

  Size? _lastReportedValidValue;

  /// The size that the navigator prefers to be.
  @override
  Size get value {
    final effectiveValue =
        _interpolation?.value ?? _routeContentSizes[_currentRoute];
    if (effectiveValue != null && effectiveValue.isFinite) {
      _lastReportedValidValue = effectiveValue;
      return effectiveValue;
    }
    return _lastReportedValidValue ?? _defaultPreferredSize;
  }

  @override
  void dispose() {
    _updateInterpolation(null);
    _updateCurrentRoute(null);
    super.dispose();
  }

  /// Called by [ResizableNavigatorRouteContentBoundary] when the size of
  /// its child widget changes.
  void didRouteContentSizeChange(Route<dynamic> route, Size contentSize) {
    assert(_routeContentSizes.containsKey(route));
    final oldPreferredSize = value;
    _routeContentSizes[route] = contentSize;
    if (value != oldPreferredSize) {
      notifyListeners();
    }
  }

  @override
  VoidCallback? didInstall(Route<dynamic> route) {
    assert(!_routeContentSizes.containsKey(route));
    _routeContentSizes[route] = _defaultPreferredSize;

    void onDispose() {
      assert(_routeContentSizes.containsKey(route));
      _routeContentSizes.remove(route);
      if (route == _currentRoute) {
        _updateCurrentRoute(null);
      }
    }

    return onDispose;
  }

  @override
  void didStartTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation, {
    bool isUserGestureInProgress = false,
  }) {
    assert(_routeContentSizes.containsKey(targetRoute));
    if (isUserGestureInProgress) {
      _startUserGestureTransition(targetRoute, animation);
    } else if (animation.status == AnimationStatus.forward) {
      _startPushTransition(targetRoute, animation);
    } else {
      assert(animation.status == AnimationStatus.reverse);
      _startPopTransition(targetRoute, animation);
    }
  }

  void _startUserGestureTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation,
  ) {
    assert(animation.status == AnimationStatus.forward);
    final initialSize = _lastReportedValidValue!;
    _updateInterpolation(
      _LazySizeTween(
        start: () => _routeContentSizes[targetRoute],
        end: () => initialSize,
      ).animate(animation),
    );
  }

  void _startPushTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation,
  ) {
    assert(animation.status == AnimationStatus.forward);
    final initialSize = _lastReportedValidValue!;
    _updateInterpolation(
      _LazySizeTween(
        start: () => initialSize,
        end: () => _routeContentSizes[targetRoute],
      ).chain(CurveTween(curve: interpolationCurve)).animate(animation),
    );
  }

  void _startPopTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation,
  ) {
    assert(animation.status == AnimationStatus.reverse);
    final initialSize = _lastReportedValidValue!;
    if (animation.value == 1) {
      _updateInterpolation(
        _LazySizeTween(
          start: () => _routeContentSizes[targetRoute],
          end: () => initialSize,
        ).chain(CurveTween(curve: interpolationCurve)).animate(animation),
      );
    } else {
      // In this case, a pop transition has started in the middle of
      // another transition. This can happen, for example, when a route
      // is popped immediately after being pushed.
      // To avoid layout shifts, we start a linear size transition
      // from a synthetic start size to the `targetRoute`'s size,
      // where the synthetic start size is calculated by _lerpEndSize.
      // This transition is such that the size equals the `initialSize`
      // at `animation.value == initialAnimationProgress`, and it eventually
      // reaches the `targetRoute`'s size at `animation.value == 1`.
      final initialAnimationProgress = animation.value;
      _updateInterpolation(
        _LazySizeTween(
          start: () => _routeContentSizes[targetRoute],
          end: () => _lerpEndSize(
            _routeContentSizes[targetRoute]!,
            initialSize,
            initialAnimationProgress,
          ),
        ).animate(animation),
      );
    }
  }

  @override
  void didEndTransition(Route<dynamic> route) {
    assert(_routeContentSizes.containsKey(route));
    _updateCurrentRoute(route);
  }
}

class _LazySizeTween extends Animatable<Size?> {
  _LazySizeTween({
    required this.start,
    required this.end,
  });

  final ValueGetter<Size?> start;
  final ValueGetter<Size?> end;

  @override
  Size? transform(double t) {
    final start = this.start();
    if (start?.isFinite != true) {
      return null;
    }
    final end = this.end();
    if (end?.isFinite != true) {
      return null;
    }
    return Size.lerp(start, end, t);
  }
}

/// Returns `se` that satisfies the equation `st = (1 - t) * se + t * ss`,
/// where [ss] is the start size and [st] is the interpolated size at time [t].
Size _lerpEndSize(Size ss, Size st, double t) {
  assert(0 < t && t <= 1);
  return Size(
    (st.width - (1 - t) * ss.width) / t,
    (st.height - (1 - t) * ss.height) / t,
  );
}
