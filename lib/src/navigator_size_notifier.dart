import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'route_transition_status.dart';

const _defaultPreferredSize = Size.infinite;

@internal
class NavigatorSizeNotifier extends ChangeNotifier
    implements ValueListenable<Size> {
  NavigatorSizeNotifier({
    required this.interpolationCurve,
  });
  final _routeContentSizes = <ModalRoute<dynamic>, Size>{};

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

  ModalRoute<dynamic>? _currentRouteRegistry;
  ModalRoute<dynamic>? get _currentRoute => _currentRouteRegistry;
  set _currentRoute(ModalRoute<dynamic>? newRoute) {
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

  void didRouteContentSizeChange(ModalRoute<dynamic> route, Size contentSize) {
    assert(_routeContentSizes.containsKey(route));
    final oldPreferredSize = value;
    _routeContentSizes[route] = contentSize;
    if (value != oldPreferredSize) {
      notifyListeners();
    }
  }

  void addRoute(ModalRoute<dynamic> route) {
    assert(!_routeContentSizes.containsKey(route));
    _routeContentSizes[route] = _defaultPreferredSize;
  }

  void removeRoute(ModalRoute<dynamic> route) {
    assert(_routeContentSizes.containsKey(route));
    _routeContentSizes.remove(route);
    if (route == _currentRoute) {
      _currentRoute = null;
    }
  }

  void didChangeTransitionStatus(RouteTransitionStatus status) {
    switch (status) {
      case NoRoute():
        _currentRoute = null;

      case TransitionCompleted(:final currentRoute):
        _currentRoute = currentRoute;

      case ForwardTransition(
              :final originRoute,
              :final destinationRoute,
              :final animation,
            ) ||
            BackwardTransition(
              :final originRoute,
              :final destinationRoute,
              :final animation,
            ):
        _interpolation = _RouteContentSizeInterpolation(
          drivenBy: animation,
          beginRouteContentSize: () => _routeContentSizes[originRoute],
          endRouteContentSize: () => _routeContentSizes[destinationRoute],
          curve: switch (_interpolation?.curve) {
            // If the current interpolation is linear, keep it linear.
            Curves.linear => Curves.linear,
            _ => interpolationCurve,
          },
        );

      case UserGestureTransition(
          :final currentRoute,
          :final previousRoute,
          :final animation,
        ):
        _interpolation = _RouteContentSizeInterpolation(
          drivenBy: animation,
          beginRouteContentSize: () => _routeContentSizes[currentRoute],
          endRouteContentSize: () => _routeContentSizes[previousRoute],
          curve: Curves.linear,
        );
    }
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
