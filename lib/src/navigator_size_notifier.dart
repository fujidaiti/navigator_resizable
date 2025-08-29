import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

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

  _RouteContentSizeInterpolation? _interpolationRegistry;
  _RouteContentSizeInterpolation? get _interpolation => _interpolationRegistry;
  set _interpolation(_RouteContentSizeInterpolation? newValue) {
    _interpolationRegistry?.removeListener(notifyListeners);
    _interpolationRegistry = newValue?..addListener(notifyListeners);
    if (newValue != null) {
      _currentRoute = null;
    }
  }

  Route<dynamic>? _currentRouteRegistry;
  Route<dynamic>? get _currentRoute => _currentRouteRegistry;
  set _currentRoute(Route<dynamic>? newRoute) {
    final oldSize = value;
    _currentRouteRegistry = newRoute;
    if (newRoute != null) {
      _interpolation = null;
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
    _interpolation = null;
    _currentRoute = null;
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
        _currentRoute = null;
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
      _interpolation = _RouteContentSizeInterpolation(
        initialSize: _lastReportedValidValue,
        targetSize: () => _routeContentSizes[targetRoute],
        curve: Curves.linear,
        drivenBy: animation.drive(Tween(begin: 1.0, end: 0.0)),
      );
    } else {
      _interpolation = _RouteContentSizeInterpolation(
        initialSize: _lastReportedValidValue,
        targetSize: () => _routeContentSizes[targetRoute],
        curve: interpolationCurve,
        drivenBy: switch (animation.status) {
          AnimationStatus.reverse =>
            animation.drive(Tween(begin: 1.0, end: 0.0)),
          _ => animation,
        },
      );
    }
  }

  @override
  void didEndTransition(Route<dynamic> route) {
    assert(_routeContentSizes.containsKey(route));
    _currentRoute = route;
  }
}

class _RouteContentSizeInterpolation extends Animation<Size?>
    with AnimationWithParentMixin<double> {
  _RouteContentSizeInterpolation({
    required Animation<double> drivenBy,
    required this.curve,
    required this.initialSize,
    required this.targetSize,
  }) : parent = drivenBy;

  @override
  final Animation<double> parent;
  final Curve curve;
  Size? initialSize;
  ValueGetter<Size?> targetSize;

  @override
  Size? get value {
    if (initialSize?.isFinite != true) {
      return null;
    }
    final targetSize = this.targetSize();
    if (targetSize?.isFinite != true) {
      return null;
    }
    debugPrint(
      'value(t=${parent.value}), curvedT=${curve.transform(parent.value)}, initialSize=$initialSize, targetSize=$targetSize) -> ${Size.lerp(initialSize, targetSize, curve.transform(parent.value))}',
    );
    return Size.lerp(
      initialSize,
      targetSize,
      curve.transform(parent.value),
    );
  }
}
