import 'package:flutter/material.dart';

import 'route_transition_status.dart';

typedef RouteTransitionStatusListener = ValueChanged<RouteTransitionStatus>;

class RouteTransitionObserver extends StatefulWidget {
  const RouteTransitionObserver({
    super.key,
    this.listeners = const [],
    required this.child,
  });

  final List<RouteTransitionStatusListener> listeners;
  final Widget child;

  @override
  State<RouteTransitionObserver> createState() =>
      RouteTransitionObserverState();

  static RouteTransitionObserverState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedRouteTransitionObserver>()
        ?.state;
  }
}

class RouteTransitionObserverState extends State<RouteTransitionObserver> {
  final Set<RouteTransitionStatusListener> _listeners = {};

  ModalRoute<dynamic>? _lastSettledRoute;
  RouteTransitionStatus? _transitionStatus;

  void _setTransitionStatus(RouteTransitionStatus status) {
    _transitionStatus = status;
    if (status is TransitionCompleted) {
      _lastSettledRoute = status.currentRoute;
    }
    for (final listener in _listeners) {
      listener(status);
    }
  }

  @override
  void initState() {
    super.initState();
    _listeners.addAll(widget.listeners);
  }

  @override
  void didUpdateWidget(RouteTransitionObserver oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listeners
      ..removeAll(oldWidget.listeners)
      ..addAll(widget.listeners);
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedRouteTransitionObserver(
      state: this,
      child: widget.child,
    );
  }

  void addListener(RouteTransitionStatusListener listener) {
    _listeners.add(listener);
  }

  void removeListener(RouteTransitionStatusListener listener) {
    _listeners.remove(listener);
  }

  @override
  void dispose() {
    _listeners.clear();
    _lastSettledRoute = null;
    _transitionStatus = null;
    super.dispose();
  }

  void _didAdd(ModalRoute<dynamic> route) {
    if (route.isCurrent) {
      assert(route.animation!.isCompleted);
      // The initial route is added.
      _setTransitionStatus(TransitionCompleted(currentRoute: route));
    }
  }

  void _didPush(ModalRoute<dynamic> route) {
    assert(route.isCurrent);
    assert(_lastSettledRoute != null);

    if (route.animation!.isCompleted) {
      // The route is pushed without transition animation.
      _setTransitionStatus(TransitionCompleted(currentRoute: route));
      return;
    }

    assert(route.animation!.status == AnimationStatus.forward);
    _setTransitionStatus(
      ForwardTransition(
        originRoute: _lastSettledRoute!,
        destinationRoute: route,
        animation: _TransitionProgress(animationOwner: route),
      ),
    );

    void transitionStatusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed && !route.offstage) {
        route.animation!.removeStatusListener(transitionStatusListener);
        if (_transitionStatus case ForwardTransition(:final destinationRoute)
            when destinationRoute == route && destinationRoute.isCurrent) {
          _setTransitionStatus(TransitionCompleted(currentRoute: route));
        }
      }
    }

    route.animation!.addStatusListener(transitionStatusListener);
  }

  void _didPopNext(Route<dynamic> route, Route<dynamic> poppedRoute) {}

  void _didChangeNext(Route<dynamic> route, Route<dynamic>? nextRoute) {}

  void _didStartUserGesture(Route<dynamic> route) {}

  void _didStopUserGesture(Route<dynamic> route) {}
}

class _InheritedRouteTransitionObserver extends InheritedWidget {
  const _InheritedRouteTransitionObserver({
    required this.state,
    required super.child,
  });

  final RouteTransitionObserverState state;

  @override
  bool updateShouldNotify(_) => true;
}

mixin ObservableModalRouteMixin<T> on ModalRoute<T> {
  RouteTransitionObserverState? _observer;

  @override
  void install() {
    super.install();
    _observer = RouteTransitionObserver.of(navigator!.context);
    navigator!.userGestureInProgressNotifier
        .addListener(_didUserGestureStatusChange);
  }

  @override
  void dispose() {
    navigator!.userGestureInProgressNotifier
        .removeListener(_didUserGestureStatusChange);
    _observer = null;
    super.dispose();
  }

  @override
  void changedExternalState() {
    super.changedExternalState();
    _observer = RouteTransitionObserver.of(navigator!.context);
  }

  @override
  TickerFuture didPush() {
    final result = super.didPush();
    _observer?._didPush(this);
    return result;
  }

  @override
  void didAdd() {
    super.didAdd();
    _observer?._didAdd(this);
  }

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    _observer?._didChangeNext(this, nextRoute);
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
    _observer?._didPopNext(this, nextRoute);
  }

  void _didUserGestureStatusChange() {
    if (navigator!.userGestureInProgress) {
      _observer?._didStartUserGesture(this);
    } else {
      _observer?._didStopUserGesture(this);
    }
  }
}

class _TransitionProgress extends Animation<double>
    with AnimationWithParentMixin<double> {
  _TransitionProgress({required this.animationOwner});

  final ModalRoute<dynamic> animationOwner;
  @override
  Animation<double> get parent => animationOwner.animation!;

  // During the first frame of a route's entrance transition, the route is
  // built with `offstage=true` and an animation progress value of 1.0.
  // This causes a discontinuity in the animation progress, as the route
  // visually appears inactive but is technically at the end of the animation.
  // To address this, the value is set to 0.0 when the route is offstage.
  @override
  double get value =>
      animationOwner.offstage ? 0.0 : animationOwner.animation!.value;
}
