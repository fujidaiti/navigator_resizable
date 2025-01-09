import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'navigator_event_observer.dart';

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

  Size? _lastReportedValue;

  /// The size that the navigator prefers to be.
  @override
  Size get value {
    final value = _interpolation?.value ??
        _routeContentSizes[_currentRoute] ??
        _lastReportedValue ??
        _defaultPreferredSize;
    return _lastReportedValue = value;
  }

  @override
  void dispose() {
    _interpolation = null;
    _currentRoute = null;
    super.dispose();
  }

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
    Route<dynamic> currentRoute,
    Route<dynamic> nextRoute,
    Animation<double> animation, {
    bool isUserGestureInProgress = false,
  }) {
    assert(_routeContentSizes.containsKey(currentRoute));
    assert(_routeContentSizes.containsKey(nextRoute));

    if (isUserGestureInProgress) {
      _interpolation = _RouteContentSizeInterpolation(
        drivenBy: animation.drive(Tween(begin: 1.0, end: 0.0)),
        beginRouteContentSize: () => _routeContentSizes[currentRoute],
        endRouteContentSize: () => _routeContentSizes[nextRoute],
        curve: Curves.linear,
      );
    } else {
      _interpolation = _RouteContentSizeInterpolation(
        drivenBy: switch (animation.status) {
          AnimationStatus.reverse =>
            animation.drive(Tween(begin: 1.0, end: 0.0)),
          _ => animation,
        },
        beginRouteContentSize: () => _routeContentSizes[currentRoute],
        endRouteContentSize: () => _routeContentSizes[nextRoute],
        curve: interpolationCurve,
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
    required this.beginRouteContentSize,
    required this.endRouteContentSize,
  }) : parent = drivenBy;

  @override
  final Animation<double> parent;
  final Curve curve;
  ValueGetter<Size?> beginRouteContentSize;
  ValueGetter<Size?> endRouteContentSize;

  @override
  Size? get value => Size.lerp(
        beginRouteContentSize(),
        endRouteContentSize(),
        curve.transform(parent.value),
      );
}
