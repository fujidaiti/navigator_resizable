import 'package:flutter/material.dart';

/// An interface for observing the lifecycle of [Route]s.
///
/// Similar to [NavigatorObserver], but can handle more fine-grained events
/// such as when a route transition animation starts or ends.
///
/// See also:
mixin NavigatorEventListener {
  /// Called when a [route] is inserted into the navigator.
  ///
  /// See [Route.install] for more details.
  VoidCallback? didInstall(Route<dynamic> route) => null;

  /// Called when a [route] is replaced by [oldRoute].
  ///
  /// See [Route.didReplace] for more details.
  void didReplace(Route<dynamic> route, Route<dynamic>? oldRoute) {}

  /// Called when a [route] is added to the navigator.
  ///
  /// See [Route.didAdd] for more details.
  void didAdd(Route<dynamic> route) {}

  /// Called when a [route] is pushed onto the navigator.
  ///
  /// See [Route.didPush] for more details.
  void didPush(Route<dynamic> route) {}

  /// Called when a request was made to pop a [route].
  ///
  /// See [Route.didPop] for more details.
  void didComplete(Route<dynamic> route, Object? result) {}

  /// Called when a [route] is popped from the navigator.
  ///
  /// See [Route.didPop] for more details.
  void didPop(Route<dynamic> route, Object? result) {}

  /// Called when the [nextRoute] of a [route] is popped from the navigator.
  ///
  /// See [Route.didPopNext] for more details.
  void didPopNext(Route<dynamic> route, Route<dynamic> nextRoute) {}

  /// Called when the [nextRoute] of a [route] changes.
  ///
  /// See [Route.didChangeNext] for more details.
  void didChangeNext(Route<dynamic> route, Route<dynamic>? nextRoute) {}

  /// Called when the [previousRoute] of a [route] changes.
  ///
  /// See [Route.didChangePrevious] for more details.
  void didChangePrevious(Route<dynamic> route, Route<dynamic>? previousRoute) {}

  /// Called when a route transition starts toward [targetRoute].
  ///
  /// The [targetRoute] is the route that will be the top-most route in
  /// the navigation stack after the transition is completed.
  /// Note that this method is called only when the [targetRoute] is of type
  /// [TransitionRoute].
  ///
  /// If the transition is driven by a user gesture,
  /// typically a swipe back gesture on iOS, [isUserGestureInProgress] is true.
  ///
  /// The [animation] is the animation that drives the transition
  /// (see [TransitionRoute.animation]). The animation's status can be used to
  /// determine the transition's direction, e.g., when popping a route, the
  /// status is [AnimationStatus.forward].
  ///
  /// Note that this method may be called multiple times in a frame, e.g., when
  /// calling [Navigator.pop] consecutively. Even in such cases,
  /// [didEndTransition] is called only once for each route transition.
  void didStartTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation, {
    bool isUserGestureInProgress = false,
  }) {}

  /// Called when a route transition ends with [route].
  ///
  /// This is also called when a first build of the navigator is completed.
  void didEndTransition(Route<dynamic> route) {}
}

/// A widget that observes the lifecycle of [Route]s.
///
/// This widget must be an ancestor of a [Navigator] widget,
/// and expects the routes in the navigator to be [ObservableRouteMixin].
///
/// There are two ways to observe the lifecycle of [Route]s:
/// 1. By providing a list of [listeners] to the constructor.
/// 2. By calling [NavigatorEventObserverState.addListener] to add a listener
///   dynamically. You can use [NavigatorEventObserver.of] to obtain the
///  [NavigatorEventObserverState] from the given [BuildContext].
class NavigatorEventObserver extends StatefulWidget {
  /// Creates a widget that observes the lifecycle of [Route]s.
  const NavigatorEventObserver({
    super.key,
    this.listeners = const [],
    required this.child,
  });

  /// The listeners that observe the lifecycle of [Route]s.
  ///
  /// Even if this list is empty, listeners that are registered
  /// using [NavigatorEventObserverState.addListener] will be notified
  /// unless they are removed by [NavigatorEventObserverState.removeListener].
  final List<NavigatorEventListener> listeners;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Navigator] widget.
  final Widget child;

  @override
  State<NavigatorEventObserver> createState() => NavigatorEventObserverState();

  /// Obtains the [NavigatorEventObserverState] from the given [context].
  static NavigatorEventObserverState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedRouteTransitionObserver>()
        ?.state;
  }
}

/// The state of [NavigatorEventObserver].
class NavigatorEventObserverState extends State<NavigatorEventObserver>
    with TickerProviderStateMixin {
  final Set<NavigatorEventListener> _listeners = {};
  final Map<Route<dynamic>, Route<dynamic>?> _nextRouteOf = {};
  final Map<Route<dynamic>, Route<dynamic>?> _previousRouteOf = {};
  NavigatorState? _navigator;
  AnimationController? _replaceAnimationController;

  @visibleForTesting
  Route<dynamic>? get lastSettledRoute => _lastSettledRoute;
  Route<dynamic>? _lastSettledRoute;

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

  /// Adds a [listener] for observing navigator events.
  void addListener(NavigatorEventListener listener) {
    _listeners.add(listener);
  }

  /// Removes a [listener] for observing navigator events.
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
    _replaceAnimationController?.dispose();
    _replaceAnimationController = null;
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
        route,
        _TransitionProgress(animationOwner: route),
      );
    });

    // Notify the listener when the transition is completed.
    void notifyTransitionEnd(AnimationStatus status) {
      if (status == AnimationStatus.completed &&
          (route is! ModalRoute || !route.offstage)) {
        route.animation!.removeStatusListener(notifyTransitionEnd);
        // At this point, the `route` might no longer be the current route,
        // e.g., when multiple routes are pushed in the same frame
        // by calling `Navigator.push` consecutively.
        if (route.isCurrent) {
          _lastSettledRoute = route;
          _notifyListeners((it) => it.didEndTransition(route));
        }
      }
    }

    route.animation!.addStatusListener(notifyTransitionEnd);
  }

  void _didPop(Route<dynamic> route, Object? result) {
    _notifyListeners((it) => it.didPop(route, result));
  }

  void _didPopNextInternal(Route<dynamic> route, Route<dynamic> poppedRoute) {
    if (_navigator!.userGestureInProgress) {
      // A swipe back gesture has popped the current route off.
      // This is handled by `_didUserGestureInProgressChange`,
      // so no action is needed here.
      return;
    }

    assert(route.isCurrent);
    if (poppedRoute is! TransitionRoute<dynamic> ||
        poppedRoute.animation!.status == AnimationStatus.dismissed) {
      _lastSettledRoute = route;
      _notifyListeners((it) => it.didEndTransition(route));
      return;
    }

    assert(poppedRoute.animation!.status == AnimationStatus.reverse);
    _notifyListeners((it) {
      it.didStartTransition(
        route,
        _TransitionProgress(animationOwner: poppedRoute),
      );
    });

    void notifyTransitionEnd(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        poppedRoute.animation!.removeStatusListener(notifyTransitionEnd);
        // At this point, the `route` might no longer be the current route.
        // This can happen, for example, if multiple routes are popped
        // in the same frame by calling `Navigator.pop` consecutively.
        if (route.isCurrent) {
          _lastSettledRoute = route;
          _notifyListeners((it) => it.didEndTransition(route));
        }
      }
    }

    poppedRoute.animation!.addStatusListener(notifyTransitionEnd);
  }

  void _didPopNext(Route<dynamic> route, Route<dynamic> nextRoute) {
    assert(_lastSettledRoute != null);
    _notifyListeners((it) => it.didPopNext(route, nextRoute));
    _didPopNextInternal(route, nextRoute);
  }

  void _didChangeNext(Route<dynamic> route, Route<dynamic>? nextRoute) {
    final didPopNext = nextRoute == null && _nextRouteOf.containsKey(route);
    _nextRouteOf[route] = nextRoute;
    _notifyListeners((it) => it.didChangeNext(route, nextRoute));
    if (didPopNext) {
      assert(_lastSettledRoute != null);
      _didPopNextInternal(route, _lastSettledRoute!);
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

    // Only animate if the replaced route was the current (settled) route.
    if (oldRoute != _lastSettledRoute) return;

    // Cancel any in-progress replace animation.
    _replaceAnimationController?.dispose();
    _replaceAnimationController = null;

    final duration = route is TransitionRoute<dynamic>
        ? route.transitionDuration
        : Duration.zero;

    if (duration == Duration.zero || route is! TransitionRoute<dynamic>) {
      _lastSettledRoute = route;
      _notifyListeners((it) => it.didEndTransition(route));
      return;
    }

    final controller = AnimationController(vsync: this, duration: duration);
    _replaceAnimationController = controller;

    // Start the animation before notifying listeners so that
    // the animation status is AnimationStatus.forward.
    controller.forward().then((_) {
      if (_replaceAnimationController == controller) {
        _replaceAnimationController = null;
        if (route.isCurrent) {
          _lastSettledRoute = route;
          _notifyListeners((it) => it.didEndTransition(route));
        }
        controller.dispose();
      }
    });

    _notifyListeners((it) {
      it.didStartTransition(route, controller);
    });
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
                destinationRoute,
                _TransitionProgress(animationOwner: originRoute),
                isUserGestureInProgress: true,
              ),
            );

          case AnimationStatus.completed:
            assert(originRoute.isCurrent);
            assert(_lastSettledRoute == originRoute);
            originRoute.animation!.removeStatusListener(statusListener);
            _notifyListeners((it) => it.didEndTransition(originRoute));

          case AnimationStatus.dismissed:
            assert(destinationRoute.isCurrent);
            _lastSettledRoute = destinationRoute;
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

/// A mixin for [Route]s that notifies the ancestor [NavigatorEventObserver]
/// of lifecycle events.
mixin ObservableRouteMixin<T> on Route<T> {
  NavigatorEventObserverState? _observer;
  VoidCallback? _onDisposeCallback;

  @override
  void install() {
    super.install();
    _observer = NavigatorEventObserver.of(navigator!.context);
    _onDisposeCallback = _observer?._didInstall(this);
  }

  @override
  void dispose() {
    _onDisposeCallback?.call();
    _onDisposeCallback = null;
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
