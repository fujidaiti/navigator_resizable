import 'package:flutter/widgets.dart';

import 'route_transition_status.dart';

class RouteTransitionObserver extends NavigatorObserver {
  final Set<RouteTransitionAwareStateMixin> _listeners = {};

  void _mount(RouteTransitionAwareStateMixin transitionAware) {
    assert(!_listeners.contains(transitionAware));
    _listeners.add(transitionAware);
  }

  void _unmount(RouteTransitionAwareStateMixin transitionAware) {
    assert(_listeners.contains(transitionAware));
    _listeners.remove(transitionAware);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalRoute && previousRoute is ModalRoute?) {
      for (final transitionAware in _listeners) {
        transitionAware._didPop(route, previousRoute);
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalRoute && previousRoute is ModalRoute?) {
      for (final transitionAware in _listeners) {
        transitionAware._didPush(route, previousRoute);
      }
    }
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    if (route is ModalRoute && previousRoute is ModalRoute?) {
      for (final transitionAware in _listeners) {
        transitionAware._didStartUserGesture(route, previousRoute);
      }
    }
  }

  @override
  void didStopUserGesture() {
    for (final transitionAware in _listeners) {
      transitionAware._didStopUserGesture();
    }
  }
}

mixin RouteTransitionAwareWidgetMixin on StatefulWidget {
  RouteTransitionObserver get transitionObserver;
}

mixin RouteTransitionAwareStateMixin<T extends RouteTransitionAwareWidgetMixin>
    on State<T> {
  RouteTransitionStatus _transitionStatus = const NoRoute();
  RouteTransitionStatus get transitionStatus => _transitionStatus;

  void _notify(RouteTransitionStatus status) {
    if (_transitionStatus != status) {
      _transitionStatus = status;
      didChangeTransitionStatus(status);
    }
  }

  void didChangeTransitionStatus(RouteTransitionStatus transition);

  void _didPush(
    ModalRoute<dynamic> route,
    ModalRoute<dynamic>? previousRoute,
  ) {
    final currentStatus = transitionStatus;

    if (previousRoute == null || route.animation!.isCompleted) {
      // There is only one roue in the history stack, or multiple routes
      // are pushed at the same time without transition animation.
      _notify(TransitionCompleted(currentRoute: route));
    } else if (route.isCurrent && currentStatus is TransitionCompleted) {
      void notifyTransitionStarted() {
        _notify(ForwardTransition(
          originRoute: currentStatus.currentRoute,
          destinationRoute: route,
          animation: route.animation!,
        ));
      }

      if (route.animation!.status == AnimationStatus.forward) {
        // Notify the listener immediately if the animation is already started.
        // Otherwise, wait for the animation to start.
        notifyTransitionStarted();
      }

      void transitionStatusListener(AnimationStatus status) {
        if (status == AnimationStatus.forward) {
          assert(_transitionStatus is! ForwardTransition);
          notifyTransitionStarted();
        } else if (status == AnimationStatus.completed && !route.offstage) {
          route.animation!.removeStatusListener(transitionStatusListener);
          if (transitionStatus is ForwardTransition) {
            _notify(TransitionCompleted(currentRoute: route));
          }
        }
      }

      route.animation!.addStatusListener(transitionStatusListener);
    }
  }

  void _didPop(
    ModalRoute<dynamic> route,
    ModalRoute<dynamic>? previousRoute,
  ) {
    if (previousRoute == null) {
      _notify(const NoRoute());
    } else {
      _notify(BackwardTransition(
        originRoute: route,
        destinationRoute: previousRoute,
        animation: route.animation!.drive(Tween(begin: 1, end: 0)),
      ));
      route.completed.whenComplete(() {
        if (transitionStatus is BackwardTransition) {
          _notify(TransitionCompleted(currentRoute: previousRoute));
        }
      });
    }
  }

  void _didStartUserGesture(
    ModalRoute<dynamic> route,
    ModalRoute<dynamic>? previousRoute,
  ) {
    _notify(UserGestureTransition(
      currentRoute: route,
      previousRoute: previousRoute!,
      animation: route.animation!.drive(Tween(begin: 1, end: 0)),
    ));
  }

  void _didStopUserGesture() {
    if (transitionStatus case final UserGestureTransition state) {
      _notify(TransitionCompleted(
        currentRoute: state.currentRoute,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    widget.transitionObserver._mount(this);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transitionObserver != oldWidget.transitionObserver) {
      oldWidget.transitionObserver._unmount(this);
      widget.transitionObserver._mount(this);
      _notify(const NoRoute());
    }
  }

  @override
  void dispose() {
    widget.transitionObserver._unmount(this);
    _notify(const NoRoute());
    super.dispose();
  }
}
