import 'package:flutter/material.dart';

mixin NavigatorEventListener {
  VoidCallback? didInstall(Route<dynamic> route) => null;
  void didReplace(Route<dynamic> route, Route<dynamic>? oldRoute) {}
  void didAdd(Route<dynamic> route) {}
  void didPush(Route<dynamic> route) {}
  void didComplete(Route<dynamic> route, Object? result) {}
  void didPop(Route<dynamic> route, Object? result) {}
  void didPopNext(Route<dynamic> route, Route<dynamic> nextRoute) {}
  void didChangeNext(Route<dynamic> route, Route<dynamic>? nextRoute) {}
  void didChangePrevious(Route<dynamic> route, Route<dynamic>? previousRoute) {}
  void didEndTransition(Route<dynamic> route) {}
  void didStartTransition(
    Route<dynamic> currentRoute,
    Route<dynamic> nextRoute,
    Animation<double> animation, {
    bool isUserGestureInProgress = false,
  }) {}
}

class NavigatorEventObserver extends StatefulWidget {
  const NavigatorEventObserver({
    super.key,
    this.listeners = const [],
    required this.child,
  });

  final List<NavigatorEventListener> listeners;
  final Widget child;

  @override
  State<NavigatorEventObserver> createState() => NavigatorEventObserverState();

  static NavigatorEventObserverState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedRouteTransitionObserver>()
        ?.state;
  }
}

class NavigatorEventObserverState extends State<NavigatorEventObserver> {
  final Set<NavigatorEventListener> _listeners = {};
  final Map<Route<dynamic>, Route<dynamic>?> _nextRouteOf = {};
  final Map<Route<dynamic>, Route<dynamic>?> _previousRouteOf = {};
  Route<dynamic>? _lastSettledRoute;
  NavigatorState? _navigator;

  void _setNavigator(NavigatorState navigator) {
    if (navigator != _navigator) {
      _navigator?.userGestureInProgressNotifier
          .removeListener(_didUserGestureInProgressChange);
      _navigator = navigator
        ..userGestureInProgressNotifier
            .addListener(_didUserGestureInProgressChange);
    }
  }

  void _notifyListeners(void Function(NavigatorEventListener) fn) {
    _listeners.forEach(fn);
  }

  void addListener(NavigatorEventListener listener) {
    _listeners.add(listener);
  }

  void removeListener(NavigatorEventListener listener) {
    _listeners.remove(listener);
  }

  @override
  void initState() {
    super.initState();
    _listeners.addAll(widget.listeners);
  }

  @override
  void didUpdateWidget(NavigatorEventObserver oldWidget) {
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

  @override
  void dispose() {
    _listeners.clear();
    _nextRouteOf.clear();
    _previousRouteOf.clear();
    _navigator?.userGestureInProgressNotifier
        .removeListener(_didUserGestureInProgressChange);
    _navigator = null;
    _lastSettledRoute = null;
    super.dispose();
  }

  VoidCallback _didInstall(Route<dynamic> route) {
    _setNavigator(route.navigator!);

    final onDisposeCallbacks = <VoidCallback>[];
    _notifyListeners((it) {
      final onDispose = it.didInstall(route);
      if (onDispose != null) {
        onDisposeCallbacks.add(onDispose);
      }
    });

    void onDisposeCallback() {
      _nextRouteOf.remove(route);
      _previousRouteOf.remove(route);
      for (final onDispose in onDisposeCallbacks) {
        onDispose();
      }
    }

    return onDisposeCallback;
  }

  void _didAdd(Route<dynamic> route) {
    for (final listener in _listeners) {
      listener.didAdd(route);
    }
    if (route.isCurrent) {
      // The initial route is added.
      _lastSettledRoute = route;
      _notifyListeners((it) => it.didEndTransition(route));
    }
  }

  void _didPush(Route<dynamic> route) {
    assert(route.isCurrent);
    assert(_lastSettledRoute != null);

    if (route is! TransitionRoute<dynamic> || route.animation!.isCompleted) {
      // The route does not have an animation or the route is pushed without
      // transition animation (e.g., when the transition duration is zero).
      _lastSettledRoute = route;
      _notifyListeners((it) {
        it.didPush(route);
        it.didEndTransition(route);
      });
      return;
    }

    assert(route.animation!.status == AnimationStatus.forward);
    _notifyListeners((it) {
      it.didPush(route);
      it.didStartTransition(
        _lastSettledRoute!,
        route,
        _TransitionProgress(animationOwner: route),
      );
    });

    // Notify the listener when the transition is completed.
    void notifyTransitionEnd(AnimationStatus status) {
      if (status == AnimationStatus.completed &&
          (route is! ModalRoute || !route.offstage)) {
        route.animation!.removeStatusListener(notifyTransitionEnd);
        assert(route.isCurrent);
        _lastSettledRoute = route;
        _notifyListeners((it) => it.didEndTransition(route));
      }
    }

    route.animation!.addStatusListener(notifyTransitionEnd);
  }

  void _didPop(Route<dynamic> route, Object? result) {
    _notifyListeners((it) => it.didPop(route, result));
  }

  void _didPopNextInternal(Route<dynamic> route) {
    final currentRoute = _lastSettledRoute!;
    if (currentRoute is! TransitionRoute<dynamic> ||
        currentRoute.animation!.status == AnimationStatus.dismissed) {
      _lastSettledRoute = route;
      _notifyListeners((it) => it.didEndTransition(route));
      return;
    }

    assert(currentRoute.animation!.status == AnimationStatus.reverse);
    _notifyListeners((it) {
      it.didStartTransition(
        currentRoute,
        route,
        _TransitionProgress(animationOwner: currentRoute),
      );
    });

    void notifyTransitionEnd(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        currentRoute.animation!.removeStatusListener(notifyTransitionEnd);
        assert(route.isCurrent);
        _lastSettledRoute = route;
        _notifyListeners((it) => it.didEndTransition(route));
      }
    }

    currentRoute.animation!.addStatusListener(notifyTransitionEnd);
  }

  void _didPopNext(Route<dynamic> route, Route<dynamic> nextRoute) {
    assert(_lastSettledRoute != null);
    _notifyListeners((it) => it.didPopNext(route, nextRoute));
    _didPopNextInternal(route);
  }

  void _didChangeNext(Route<dynamic> route, Route<dynamic>? nextRoute) {
    final didPopNext = nextRoute == null && _nextRouteOf.containsKey(route);
    _nextRouteOf[route] = nextRoute;
    _notifyListeners((it) => it.didChangeNext(route, nextRoute));
    if (didPopNext) {
      _didPopNextInternal(route);
    }
  }

  void _didChangePrevious(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _previousRouteOf[route] = previousRoute;
    _notifyListeners((it) => it.didChangePrevious(route, previousRoute));
  }

  void _didComplete(Route<dynamic> route, Object? result) {
    _notifyListeners((it) => it.didComplete(route, result));
  }

  void _didReplace(Route<dynamic> route, Route<dynamic>? oldRoute) {
    _notifyListeners((it) => it.didReplace(route, oldRoute));
  }

  void _didUserGestureInProgressChange() {
    assert(_navigator != null);
    if (_navigator!.userGestureInProgress) {
      final originRoute = _lastSettledRoute! as TransitionRoute<dynamic>;
      assert(originRoute.animation!.status == AnimationStatus.completed);
      final destinationRoute = _previousRouteOf[originRoute]!;

      void statusListener(AnimationStatus status) {
        switch (status) {
          case AnimationStatus.forward:
            _notifyListeners(
              (it) => it.didStartTransition(
                originRoute,
                destinationRoute,
                _TransitionProgress(animationOwner: originRoute),
                isUserGestureInProgress: true,
              ),
            );

          case AnimationStatus.completed:
            originRoute.animation!.removeStatusListener(statusListener);
            _notifyListeners((it) => it.didEndTransition(originRoute));

          case AnimationStatus.dismissed:
            originRoute.animation!.removeStatusListener(statusListener);
            _notifyListeners((it) => it.didEndTransition(destinationRoute));

          case AnimationStatus.reverse:
          // Do nothing.
        }
      }

      originRoute.animation!.addStatusListener(statusListener);
    }
  }
}

class _InheritedRouteTransitionObserver extends InheritedWidget {
  const _InheritedRouteTransitionObserver({
    required this.state,
    required super.child,
  });

  final NavigatorEventObserverState state;

  @override
  bool updateShouldNotify(_) => true;
}

mixin ObservableModalRouteMixin<T> on Route<T> {
  NavigatorEventObserverState? _observer;
  VoidCallback? onDisposeCallback;

  @override
  void install() {
    super.install();
    _observer = NavigatorEventObserver.of(navigator!.context);
    onDisposeCallback = _observer?._didInstall(this);
  }

  @override
  void dispose() {
    onDisposeCallback?.call();
    onDisposeCallback = null;
    _observer = null;
    super.dispose();
  }

  @mustCallSuper
  @override
  TickerFuture didPush() {
    final result = super.didPush();
    _observer?._didPush(this);
    return result;
  }

  @mustCallSuper
  @override
  void didAdd() {
    super.didAdd();
    _observer?._didAdd(this);
  }

  @mustCallSuper
  @override
  bool didPop(T? result) {
    final didPopResult = super.didPop(result);
    _observer?._didPop(this, result);
    return didPopResult;
  }

  @mustCallSuper
  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    _observer?._didChangePrevious(this, previousRoute);
  }

  @mustCallSuper
  @override
  void didComplete(T? result) {
    super.didComplete(result);
    _observer?._didComplete(this, result);
  }

  @mustCallSuper
  @override
  void didReplace(Route<dynamic>? oldRoute) {
    super.didReplace(oldRoute);
    _observer?._didReplace(this, oldRoute);
  }

  @mustCallSuper
  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    _observer?._didChangeNext(this, nextRoute);
  }

  @mustCallSuper
  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
    _observer?._didPopNext(this, nextRoute);
  }
}

class _TransitionProgress extends Animation<double>
    with AnimationWithParentMixin<double> {
  _TransitionProgress({required this.animationOwner});

  final TransitionRoute<dynamic> animationOwner;
  @override
  Animation<double> get parent => animationOwner.animation!;

  // During the first frame of a route's entrance transition, the route is
  // built with `offstage=true` and an animation progress value of 1.0.
  // This causes a discontinuity in the animation progress, as the route
  // visually appears inactive but is technically at the end of the animation.
  // To address this, the value is set to 0.0 when the route is offstage.
  @override
  double get value => switch (animationOwner) {
        ModalRoute<dynamic>(offstage: true) => 0.0,
        final it => it.animation!.value,
      };
}
