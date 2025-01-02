import 'package:flutter/material.dart';

import 'route_transition_status.dart';

typedef RouteTransitionStatusListener = ValueChanged<RouteTransitionStatus>;

class RouteTransitionObserver extends StatefulWidget {
  const RouteTransitionObserver({
    super.key,
    required this.child,
  });

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
    super.dispose();
  }

  void _didPushRoute(Route<dynamic> route) {}

  void _didPopNextRoute(Route<dynamic> route, Route<dynamic> poppedRoute) {}

  void _didChangeNextRoute(Route<dynamic> route, Route<dynamic>? nextRoute) {}

  void _didStartUserGesture(Route<dynamic> route) {}
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
  RouteTransitionObserver? _routeTransitionObserver;

  @override
  void install() {
    super.install();
    navigator!.userGestureInProgressNotifier
        .addListener(_didUserGestureStatusChange);
  }

  @override
  void dispose() {
    navigator!.userGestureInProgressNotifier
        .removeListener(_didUserGestureStatusChange);
    super.dispose();
  }

  @override
  TickerFuture didPush() {
    final result = super.didPush();
    return result;
  }

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    // TODO: implement didChangeNext
    super.didChangeNext(nextRoute);
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
  }

  void _didUserGestureStatusChange() {}
}
