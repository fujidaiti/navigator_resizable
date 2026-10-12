import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' as physics;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A widget that resizes the child [Navigator] to match the intrinsic size of
/// the current [Route]'s content.
///
/// Think of this like a resizable box with nested pages, whose size changes as
/// the current page goes from one to another. If the first page wants to be
/// 200x200, this widget has that size. If the second page wants to be 400x400
/// and the user goes to the second page, this widget then becomes a 400x400
/// box.
///
/// Technically, this widget lets the top-level widget hosted by the navigator's
/// current route freely determine its width and height, and sizes the navigator
/// and itself to match those dimensions.
///
/// During route transitions, this widget gradually grows or shrinks toward the
/// next route's size along with the transition animation, instead of changing
/// abruptly. Note that, however, the navigator keeps its previous size during
/// the transition and jumps to the target size when it completes. That is, the
/// navigator may be bigger or smaller than this widget's boundary box while
/// transitioning, and the overflowing portions, if any, are visually clipped.
///
/// ### Routes and Pages
///
/// The [NavigatorResizable] can respect the content size of a route
/// only if the route's content is wrapped in a [ResizableRouteContent].
/// Any standard route or page class can be used, as long as this holds.
/// This is especially important during route transitions, as the
/// [NavigatorResizable] can animate its size in sync with the transition
/// animation only when both the current route and the next route satisfy
/// that requirement. Otherwise, the navigator's size changes abruptly
/// without any animation.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => ResizableRouteContent(child: MyPage()),
///   ),
/// );
/// ```
///
/// ### Android's predictive back gesture
///
/// Flutter's [PredictiveBackPageTransitionsBuilder], which is the default page
/// transition for Android, drives the route's transition animation as the back
/// gesture progresses, and resets that animation to 1.0 at the moment the
/// gesture is committed. The navigator's size therefore follows the gesture
/// and then jumps back to the size of the route being popped before it
/// animates to the target size.
///
/// Which page transition to use is the application's decision, so the
/// [NavigatorResizable] does not interfere with it. If you prefer a size
/// transition that runs only after the gesture is committed, choose a page
/// transition that does not support the predictive back gesture, such as
/// [FadeForwardsPageTransitionsBuilder]:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: {
///         TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
///       },
///     ),
///   ),
///   ...
/// );
/// ```
///
/// Note that the [child] navigator and its routes are constrained by the
/// constraints imposed by the parent widget of the [NavigatorResizable].
/// To ensure that the route content fills the entire available space,
/// the easiest way is to set the content widget's width or height
/// to [double.infinity].
///
/// ```dart
/// MaterialPageRoute(
///   builder: (context) {
///     return ResizableRouteContent(
///       child: Container(
///         color: Colors.white,
///         width: double.infinity,
///         height: double.infinity,
///       ),
///     );
///   },
/// );
/// ```
///
/// For more advanced use cases, you can create a custom route compatible with
/// [NavigatorResizable] by returning a [ResizableRouteContent] from
/// [ModalRoute.buildPage].
///
/// ```dart
/// class CustomRoute<T> extends ModalRoute<T> {
///   @override
///   Widget buildPage(
///     BuildContext context,
///     Animation<double> animation,
///     Animation<double> secondaryAnimation,
///   ) {
///     return ResizableRouteContent(child: builder(context));
///   }
/// }
/// ```
///
/// ### Caveats
///
/// Avoid wrapping the navigator in widgets that add extra space around it,
/// such as [Padding]. Zero-size widgets, such as [GestureDetector] and
/// [ColoredBox], and widgets without render objects, such as [Theme] and
/// [AnimatedBuilder], are all acceptable.
///
/// Do not place [NavigatorResizable] inside a widget with a tight constraint.
/// Otherwise it adopts the size enforced by the constraints, ignoring the size
/// of the current route's content. Typically, [Center] and [Align] are good
/// choices for the parent widget.
///
/// ### Example
///
/// The following example demonstrates a resizable window centered within
/// a [Scaffold] that can display multiple pages:
///
/// ```dart
/// Navigator nestedNavigator;
/// return Scaffold(
///   body: Center(
///     child: Material(
///       color: Colors.white,
///       child: NavigatorResizable(
///         child: nestedNavigator,
///       ),
///     ),
///   ),
/// );
/// ```
/// You can use any standard navigation methods, such as [Navigator.push],
/// [Navigator.pop], [named routes][1],
/// and the [Pages API][2],
/// with [NavigatorResizable] as you would with a regular [Navigator]:
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) {
///       return ResizableRouteContent(
///         child: Container(
///           color: Colors.red,
///           width: 300,
///           height: 300,
///         ),
///       );
///     },
///   ),
/// );
/// ```
///
/// See the [/example][3] directory for more practical examples.
///
/// [1]: https://api.flutter.dev/flutter/widgets/Navigator-class.html#:~:text=Using%20named%20navigator%20routes
/// [2]: https://api.flutter.dev/flutter/widgets/Navigator-class.html#:~:text=the%20current%20page.-,Using%20the%20Pages%20API,-The%20Navigator%20will
/// [3]: https://github.com/fujidaiti/navigator_resizable/tree/main/example/lib
class NavigatorResizable extends StatefulWidget {
  /// Creates a widget that resizes the child [Navigator] to match the intrinsic
  /// size of the current [Route]'s content.
  const NavigatorResizable({
    super.key,
    this.interpolationCurve = Curves.easeInOutCubic,
    required this.child,
  });

  /// The [Curve] used to interpolate the size of this widget during
  /// route transitions.
  ///
  /// Defaults to [Curves.easeInOutCubic].
  final Curve interpolationCurve;

  /// The [Navigator] to be resized.
  ///
  /// This is not necessary to be a raw [Navigator]. A navigator wrapped in
  /// zero-sized widgets, such as [GestureDetector] and [ColoredBox], or widgets
  /// without render objects, such as [Theme] and [AnimatedBuilder], are all
  /// acceptable.
  final Widget child;

  @override
  State<NavigatorResizable> createState() => _NavigatorResizableState();
}

/// Architecture Overview
///
/// The [Navigator] has a less well-known nature: when it is given an unbounded
/// constraint, it shrink-wraps to the top-level widget hosted by the current
/// route. The [NavigatorResizable] utilizes this fact to achieve the desired
/// behavior, involving two custom render objects:
///
///   - [_RenderNavigatorResizable], which lays out the navigator with a
///     [BoxConstraints] whose maxWidth and maxHeight are [double.infinity].
///     The navigator and this render object shrink-wrap to the route content.
///
///   - [_RenderRouteContentBoundary], which lays out the content of the
///     navigator's routes with constraints imposed by the parent render object
///     for the [NavigatorResizable], to let the content freely determine its
///     size, ignoring the constraints provided by the navigator.
///
/// The former is important to avoid a one-frame delay issue, where changes in
/// the content's size (due to adding/removing list items, for example) are
/// reflected in the [NavigatorResizable]'s size with a one-frame lag after the
/// frame in which the content size was actually changed. While it looks like a
/// trivial problem, it can be a cause of some visual glitches in consumer apps,
/// as reported [here][1].
///
/// [1]: https://github.com/fujidaiti/smooth_sheets/issues/307
///
/// This issue occurs when the navigator is given a finite constraint. In this
/// case, the navigator always expands to fill the available space and forces
/// the route content to match that size. Even in this way, it is still possible
/// to _visually_ shrink-wrap the navigator to the route content, by laying out
/// the route content in an [OverflowBox] with an unbounded constraint,
/// observing its size, and bubbling it up to the [NavigatorResizable] to clip
/// the navigator's painting area to match the content's boundaries.
///
/// While the idea seems to work, it causes the one-frame delay issue. This is
/// because, with a finite constraint, the navigator sizes itself to fill the
/// available space **before** laying out the route content, meaning that the
/// [NavigatorResizable] cannot read the route content's size when determining
/// its size. It is notified of the new content size after the route's layout,
/// but since the layout phase for the [NavigatorResizable] is already done,
/// there is no chance to reflect that value in the resizable's size in the
/// same frame.
///
/// In addition to avoiding the issue, shrink-wrapping the navigator to the
/// route's content also allows it to correctly render [OverlayEntry]s such as
/// popup menus. This is not possible with the clip-based architecture mentioned
/// above, where the size of the navigator and its [Overlay] never change
/// regardless of the route content's size, so overlay entries rendered at
/// the bottom of the navigator may be clipped out if the route content's size
/// is much smaller than the navigator (see [this issue][2] for more details).
/// With the shrink-wrapping, the overlay also shrink-wraps, so the entries
/// never go outside the route's boundaries.
///
/// [2]: https://github.com/fujidaiti/smooth_sheets/issues/167
///
/// The latter render object, which lays out a route content with the bypassed
/// ancestor constraint, is technically optional, but designed intentionally.
/// Since the bypassed constraint is finite, route content widgets can claim
/// that they want to be as large as possible by specifying
/// [double.infinity] to their width and height, without knowing the actual
/// available space during the build phase. If content was laid out with the
/// navigator's constraint, using [double.infinity] would cause a Flutter
/// assertion error since that constraint is unbounded.
///
/// During route transitions, the [NavigatorResizable] gradually grows or
/// shrinks toward the next route's size along with the transition animation,
/// instead of changing abruptly. Note that, however, the navigator keeps its
/// previous size during the transition and jumps to the target size when it
/// completes. That is, the navigator may be bigger or smaller than the
/// [NavigatorResizable]'s boundary box while transitioning, and the overflowing
/// portions, if any, are visually clipped out.
class _NavigatorResizableState extends State<NavigatorResizable> {
  /// Represents an interpolated size of the navigator during a transition.
  /// The value is available only when the transition is running; otherwise
  /// it reports null.
  late final _SizeProxyAnimation _sizeInterpolation;

  /// The content boundary of every route that is currently installed in the
  /// child navigator, keyed by the route it belongs to.
  ///
  /// A route enters this map when its [ResizableRouteContent] is mounted,
  /// which happens after [Route.install], and leaves it when that widget is
  /// disposed. Routes that the navigator has announced but not yet installed,
  /// and routes that have already been disposed, are therefore never in it.
  final _routeContents = <ModalRoute<dynamic>, _ResizableRouteContentState>{};

  /// The navigator that owns the tracked routes.
  ///
  /// Obtained from the routes themselves, since the navigator is a descendant
  /// of this widget and cannot be looked up from this context.
  NavigatorState? _navigator;

  _TransitionState _state = const _Settled(null);

  @override
  void initState() {
    super.initState();
    _sizeInterpolation = _SizeProxyAnimation()
      ..addListener(_handleSizeInterpolationChange);
  }

  void _handleSizeInterpolationChange() {
    if (_state case final _InTransition state) {
      state.lastInterpolatedSize =
          _sizeInterpolation.value ?? state.lastInterpolatedSize;
    }
  }

  /// The size to start the next transition from, which is the size currently
  /// displayed.
  Size? get _originSize {
    return _sizeInterpolation.value ??
        switch (_state) {
          _Settled(:final route) => _sizeOf(route),
          final _InTransition state =>
            state.lastInterpolatedSize ?? _sizeOf(state.settledRoute),
        };
  }

  @override
  void dispose() {
    _navigator?.userGestureInProgressNotifier.removeListener(
      _handleStateChange,
    );
    _navigator = null;
    _sizeInterpolation
      ..removeListener(_handleSizeInterpolationChange)
      ..dispose();
    super.dispose();
  }

  void _registerRouteContent(
    ModalRoute<dynamic> route,
    _ResizableRouteContentState content,
  ) {
    assert(!_routeContents.containsKey(route));
    _routeContents[route] = content;
    route.animation?.addStatusListener(_handleAnimationStatusChange);

    final navigator = route.navigator;
    if (navigator != null && navigator != _navigator) {
      _navigator?.userGestureInProgressNotifier.removeListener(
        _handleStateChange,
      );
      _navigator = navigator
        ..userGestureInProgressNotifier.addListener(_handleStateChange);
    }

    _handleStateChange();
  }

  void _unregisterRouteContent(ModalRoute<dynamic> route) {
    if (_routeContents.remove(route) == null) {
      return;
    }
    route.animation?.removeStatusListener(_handleAnimationStatusChange);
    // A route that still has a navigator is only temporarily detached from
    // the tree, for example when the framework reparents the route's content
    // as a back gesture starts, and it registers itself again in the same
    // frame. Only a disposed route is forgotten.
    if (route.navigator == null) {
      switch (_state) {
        case _Settled(route: final settledRoute) when settledRoute == route:
          _state = const _Settled(null);
        case final _InTransition state when state.settledRoute == route:
          state.settledRoute = null;
        case _:
          break;
      }
    }
    _handleStateChange();
  }

  void _handleAnimationStatusChange(AnimationStatus status) {
    _handleStateChange();
  }

  Size? _sizeOf(ModalRoute<dynamic>? route) {
    return route == null ? null : _routeContents[route]?.contentSize;
  }

  /// The tracked route that is on top of the navigator's stack and visible to
  /// the user, or null if no tracked route is current.
  ModalRoute<dynamic>? get _currentRoute {
    for (final route in _routeContents.keys) {
      if (route.isCurrent) {
        return route;
      }
    }
    return null;
  }

  /// The tracked route that is visually on top, which is the topmost route
  /// that is animating out if there is one, and [_currentRoute] otherwise.
  ///
  /// A route that has been popped or removed stays tracked until its exit
  /// animation completes, and it is always above every active route: a removal
  /// in the middle of the stack completes within the same frame and never
  /// animates. The topmost one is the one with nothing above it, which is
  /// the one whose [TransitionRoute.secondaryAnimation] is dismissed.
  ModalRoute<dynamic>? get _topRoute {
    ModalRoute<dynamic>? anyExitingRoute;
    for (final route in _routeContents.keys) {
      if (!route.isActive) {
        anyExitingRoute ??= route;
        if (route.secondaryAnimation?.status == AnimationStatus.dismissed) {
          return route;
        }
      }
    }
    return anyExitingRoute ?? _currentRoute;
  }

  /// The tracked route directly below [route], or null if there is none.
  ///
  /// Neither [Route] nor [NavigatorState] exposes the navigator's stack, but
  /// [TransitionRoute] wires the `secondaryAnimation` of a route to the
  /// `animation` of the route directly above it, so the relation is
  /// recoverable by comparing the animations those proxies ultimately point
  /// at.
  ModalRoute<dynamic>? _routeBelow(ModalRoute<dynamic> route) {
    final target = _unwrapAnimation(route.animation);
    if (target == null) {
      return null;
    }
    for (final other in _routeContents.keys) {
      if (other != route &&
          identical(_unwrapAnimation(other.secondaryAnimation), target)) {
        return other;
      }
    }
    return null;
  }

  /// Follows [ProxyAnimation.parent] and [TrainHoppingAnimation.currentTrain]
  /// until neither applies, to obtain the animation object that [animation]
  /// ultimately reports the value of.
  static Animation<double>? _unwrapAnimation(Animation<double>? animation) {
    var result = animation;
    while (true) {
      switch (result) {
        case final ProxyAnimation it when it.parent != null:
          result = it.parent;
        case final TrainHoppingAnimation it:
          result = it.currentTrain;
        case _:
          return result;
      }
    }
  }

  static bool _isAnimating(Animation<double>? animation) {
    return animation != null &&
        (animation.status == AnimationStatus.forward ||
            animation.status == AnimationStatus.reverse);
  }

  /// Recomputes the transition state from the tracked routes.
  ///
  /// This is the only entry point for state changes. It is called whenever a
  /// route is registered or unregistered, whenever a route's content is
  /// rebuilt because its `isCurrent` or `isActive` changed, whenever the
  /// animation of a tracked route changes its status, and whenever the
  /// navigator starts or stops a user gesture.
  ///
  /// It must never mark an ancestor element as dirty, since it may run during
  /// the build phase; assigning [_SizeProxyAnimation.parent] only marks
  /// [_RenderNavigatorResizable] as needing layout, which is legal at any
  /// point before the layout phase.
  void _handleStateChange() {
    if (!mounted) {
      return;
    }

    final currentRoute = _currentRoute;
    if (currentRoute == null) {
      // No tracked route is current. This happens for a moment during a
      // transition, when the previous route has been notified that it is no
      // longer current but the new one has not been installed yet.
      return;
    }

    final isUserGestureInProgress = _navigator?.userGestureInProgress ?? false;

    final topRoute = _topRoute;
    final exitAnimation =
        topRoute != null &&
            topRoute != currentRoute &&
            _isAnimating(topRoute.animation)
        ? topRoute.animation
        : null;

    final ModalRoute<dynamic> destinationRoute;
    final Animation<double>? driver;
    final bool isGestureDriven;
    if (exitAnimation != null) {
      // A route is animating out. This is also the case while a back gesture
      // is still reported as in progress but has already been committed, which
      // is what Android's predictive back gesture does.
      destinationRoute = currentRoute;
      driver = exitAnimation;
      isGestureDriven = false;
    } else if (isUserGestureInProgress) {
      // The stack does not change until a back gesture is committed, so the
      // route being dragged is still the current one and the destination is
      // the route below it.
      destinationRoute = _routeBelow(currentRoute) ?? currentRoute;
      driver = currentRoute.animation;
      isGestureDriven = true;
    } else if (_isAnimating(currentRoute.animation)) {
      destinationRoute = currentRoute;
      driver = currentRoute.animation;
      isGestureDriven = false;
    } else {
      destinationRoute = currentRoute;
      driver = null;
      isGestureDriven = false;
    }

    if (driver == null && !isUserGestureInProgress) {
      _endTransition(destinationRoute);
      return;
    }

    final previousState = _state;
    if (driver == null ||
        (previousState is _InTransition &&
            destinationRoute == previousState.destinationRoute &&
            driver == previousState.driver &&
            isGestureDriven == (previousState is _GestureDriven))) {
      // Either a gesture is in progress but nothing is animating, which is the
      // case while the dragged route is held at either end of its animation,
      // or the running transition is unchanged. In both cases the current size
      // interpolation stays as it is.
      return;
    }

    // A transition that replaces another one inherits its settled route and
    // its last interpolated size, which are the fallbacks for the origin size.
    final (settledRoute, lastInterpolatedSize) = switch (previousState) {
      _Settled(:final route) => (route, null),
      _InTransition() => (
        previousState.settledRoute,
        previousState.lastInterpolatedSize,
      ),
    };
    _state = isGestureDriven
        ? _GestureDriven(
            settledRoute: settledRoute,
            destinationRoute: destinationRoute,
            driver: driver,
            lastInterpolatedSize: lastInterpolatedSize,
          )
        : _AnimationDriven(
            settledRoute: settledRoute,
            destinationRoute: destinationRoute,
            driver: driver,
            lastInterpolatedSize: lastInterpolatedSize,
          );
    if (isGestureDriven) {
      _startUserGestureTransition(destinationRoute, driver);
    } else if (driver == currentRoute.animation) {
      _startPushTransition(destinationRoute, driver);
    } else {
      _startPopTransition(destinationRoute, driver);
    }
  }

  void _startUserGestureTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation,
  ) {
    assert(animation.isForwardOrCompleted);
    final initialSize = _originSize;
    _sizeInterpolation.parent = _LazySizeTween(
      start: () => _sizeOf(targetRoute as ModalRoute<dynamic>),
      end: () => initialSize,
    ).animate(animation);
  }

  void _startPushTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation,
  ) {
    assert(animation.isForwardOrCompleted);
    final initialSize = _originSize;
    _sizeInterpolation.parent = _LazySizeTween(
      start: () => initialSize,
      end: () => _sizeOf(targetRoute as ModalRoute<dynamic>),
    ).chain(CurveTween(curve: widget.interpolationCurve)).animate(animation);
  }

  void _startPopTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation,
  ) {
    assert(!animation.isForwardOrCompleted);
    final initialSize = _originSize;

    Size? targetRouteSize() => _sizeOf(targetRoute as ModalRoute<dynamic>);

    if (animation.value == 1) {
      _sizeInterpolation.parent = _LazySizeTween(
        start: targetRouteSize,
        end: () => initialSize,
      ).chain(CurveTween(curve: widget.interpolationCurve)).animate(animation);
    } else {
      // In this case, a pop transition has started in the middle of another
      // transition. This can happen, for example, when a route is popped
      // immediately after being pushed.
      //
      // To avoid layout shifts, we start a linear size transition from
      // a synthetic start size to the target size, where the synthetic start
      // size is calculated by _lerpEndSize. This transition is such that the
      // size equals the initialSize when animation.value is
      // initialAnimationProgress, and it eventually reaches the target size
      // when animation.value is 1.
      final initialAnimationProgress = animation.value;
      _sizeInterpolation.parent = _LazySizeTween(
        start: targetRouteSize,
        end: () => _lerpEndSize(
          targetRouteSize()!,
          initialSize!,
          initialAnimationProgress,
        ),
      ).animate(animation);
    }
  }

  void _endTransition(ModalRoute<dynamic> destinationRoute) {
    final settledRoute = switch (_state) {
      _Settled(:final route) => route,
      _InTransition(:final settledRoute) => settledRoute,
    };
    if (settledRoute == null ||
        // Ignore routes that are added but not displayed.
        // For example, when jumping from /a to /a/b/c, this can be called
        // with route b before the transition animation starts, but it has no
        // geometry information since it's not laid out.
        _sizeOf(destinationRoute) != null) {
      _state = _Settled(destinationRoute);
      _sizeInterpolation.parent = null;
    } else {
      _state = _Settled(settledRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _NavigatorResizableScope(
      state: this,
      child: LayoutBuilder(
        builder: (_, constraints) {
          return _BypassedNavigatorConstraints(
            value: constraints,
            child: _RenderNavigatorResizableWidget(
              sizeTransition: _sizeInterpolation,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// The state of the size transition of a [NavigatorResizable].
sealed class _TransitionState {
  const _TransitionState();
}

/// No transition is running, and the navigator is sized to [route].
final class _Settled extends _TransitionState {
  const _Settled(this.route);

  final ModalRoute<dynamic>? route;
}

/// A transition towards [destinationRoute] is running.
sealed class _InTransition extends _TransitionState {
  _InTransition({
    required this.settledRoute,
    required this.destinationRoute,
    required this.driver,
    required this.lastInterpolatedSize,
  });

  /// The route the navigator was sized to before the transition started.
  ///
  /// This becomes null if the route is disposed during the transition.
  ModalRoute<dynamic>? settledRoute;

  final ModalRoute<dynamic> destinationRoute;

  /// The animation that drives the progress of the transition.
  final Animation<double> driver;

  /// The most recent non-null value of the size interpolation within the
  /// transition.
  ///
  /// The size interpolation reports null as soon as one of the routes it
  /// interpolates between leaves the tracked set, which happens when a
  /// transition is replaced by another one that removes the route the previous
  /// transition was heading to. This keeps the size the user last saw
  /// available as the origin of the new transition.
  Size? lastInterpolatedSize;
}

/// A transition driven by a route's animation, such as a push or a pop.
final class _AnimationDriven extends _InTransition {
  _AnimationDriven({
    required super.settledRoute,
    required super.destinationRoute,
    required super.driver,
    required super.lastInterpolatedSize,
  });
}

/// A transition driven by a user's back gesture.
final class _GestureDriven extends _InTransition {
  _GestureDriven({
    required super.settledRoute,
    required super.destinationRoute,
    required super.driver,
    required super.lastInterpolatedSize,
  });
}

/// Exposes the [_NavigatorResizableState] to the [ResizableRouteContent]
/// widgets in the route contents below it.
class _NavigatorResizableScope extends InheritedWidget {
  const _NavigatorResizableScope({
    required this.state,
    required super.child,
  });

  final _NavigatorResizableState state;

  static _NavigatorResizableState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_NavigatorResizableScope>()
        ?.state;
  }

  @override
  bool updateShouldNotify(_NavigatorResizableScope oldWidget) =>
      state != oldWidget.state;
}

class _BypassedNavigatorConstraints extends InheritedWidget {
  const _BypassedNavigatorConstraints({
    required this.value,
    required super.child,
  });

  final BoxConstraints value;

  @override
  bool updateShouldNotify(_BypassedNavigatorConstraints oldWidget) =>
      value != oldWidget.value;
}

class _RenderNavigatorResizableWidget extends SingleChildRenderObjectWidget {
  const _RenderNavigatorResizableWidget({
    required this.sizeTransition,
    required super.child,
  });

  final ValueListenable<Size?> sizeTransition;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderNavigatorResizable(sizeTransition: sizeTransition);
  }
}

class _RenderNavigatorResizable extends RenderAligningShiftedBox {
  _RenderNavigatorResizable({required this.sizeTransition})
    : super(alignment: Alignment.topLeft, textDirection: null) {
    sizeTransition.addListener(markNeedsLayout);
  }

  final ValueListenable<Size?> sizeTransition;

  /// The visible area of the descendant Navigator.
  ///
  /// Used in [paint] and [hitTest].
  /// The size of this rect should be kept in sync with the value of
  /// [sizeTransition] and the offset should be always [Offset.zero].
  late Rect _visibleBounds;

  @override
  bool get sizedByParent => false;

  @override
  void dispose() {
    sizeTransition.removeListener(markNeedsLayout);
    super.dispose();
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return switch (sizeTransition.value) {
      null => child!.getDryLayout(
        const BoxConstraints(
          maxHeight: double.infinity,
          maxWidth: double.infinity,
        ),
      ),
      final size => constraints.constrain(size),
    };
  }

  @override
  void performLayout() {
    assert(
      !constraints.isTight,
      'The NavigatorResizable widget was given a tight constraint. '
      'This is not allowed because it needs to size itself to fit '
      'the current route content. Consider wrapping the NavigatorResizable '
      'with a widget that provides a non-tight constraint, such as Align '
      'or Center.\n'
      'The given constraint was: $constraints, which was given by '
      'the parent: ${parent?.parent.runtimeType}.',
      // We refer to parent.parent here as the parent is always the render
      // object for the LayoutBuilder that the NavigatorResizable builds
      // internally, which isn't what developers insert by themselves.
    );
    assert(
      constraints.hasBoundedHeight && constraints.hasBoundedWidth,
      'The NavigatorResizable widget was given an unbounded constraint. '
      'This is not allowed because otherwise the routes within the underlying '
      'Navigator would not know their valid maximum size. This becomes '
      'especially problematic when a route specifies double.infinity for width '
      'or height to expand to the available space, which causes a layout error '
      'since the parent Navigator does not provide finite bounds.\n'
      'Make sure that NavigatorResizable is not wrapped in a widget that '
      'passes an unbounded constraint to its children, such as Column or Row. '
      'The given constraint was $constraints, which was given by '
      '${parent?.parent.runtimeType}.',
    );

    child!.layout(
      const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      parentUsesSize: true,
    );

    size = switch (sizeTransition.value) {
      null => constraints.constrain(Size.copy(child!.size)),
      final s => constraints.constrain(s),
    };

    _visibleBounds = Offset.zero & size;
    alignChild();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(_visibleBounds.size.nearEqual(size));
    layer = context.pushClipRect(
      needsCompositing,
      offset,
      _visibleBounds,
      super.paint,
      oldLayer: layer as ClipRectLayer?,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    assert(_visibleBounds.size.nearEqual(size));
    return _visibleBounds.contains(position) &&
        super.hitTest(result, position: position);
  }
}

/// Wraps the content of a [Route] managed by the [Navigator] under a
/// [NavigatorResizable].
///
/// This is the only requirement the [NavigatorResizable] imposes on a route:
/// the route's content must be wrapped in this widget. Any standard route or
/// page class, such as [MaterialPageRoute] and [MaterialPage], can be used as
/// long as this widget is the outermost parent of its content.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => ResizableRouteContent(child: MyPage()),
///   ),
/// );
/// ```
///
class ResizableRouteContent extends StatefulWidget {
  /// Creates a container for the content of a [Route] managed by the
  /// [Navigator] under a [NavigatorResizable].
  const ResizableRouteContent({
    super.key,
    required this.child,
  });

  /// The [Route]'s content.
  final Widget child;

  @override
  State<ResizableRouteContent> createState() => _ResizableRouteContentState();
}

class _ResizableRouteContentState extends State<ResizableRouteContent> {
  final _boundaryKey = GlobalKey();

  _NavigatorResizableState? _resizable;
  ModalRoute<dynamic>? _route;
  bool _isRegistered = false;

  /// The natural size of the route content, measured in the last layout pass,
  /// or null if the content has not been laid out yet.
  Size? get contentSize {
    final renderObject =
        _boundaryKey.currentContext?.findRenderObject()
            as _RenderRouteContentBoundary?;
    return renderObject?.lastMeasuredChildSize;
  }

  void _register() {
    if (!_isRegistered && _route != null && _resizable != null) {
      _isRegistered = true;
      _resizable!._registerRouteContent(_route!, this);
    }
  }

  void _unregister() {
    if (_isRegistered) {
      _isRegistered = false;
      _resizable!._unregisterRouteContent(_route!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Depending on ModalRoute.of makes this widget rebuild whenever the route's
    // isCurrent changes, which is how the NavigatorResizable is notified of
    // stack changes that involve no animation at all, such as Navigator.replace
    // and a route with a zero transition duration.
    final route = ModalRoute.of(context);
    assert(
      route != null,
      'ResizableRouteContent must be used within a ModalRoute.',
    );
    final resizable = _NavigatorResizableScope.of(context);
    assert(
      resizable != null,
      'ResizableRouteContent must be used within a Navigator '
      'that is a descendant of a NavigatorResizable.',
    );

    if (route != _route || resizable != _resizable) {
      _unregister();
      _route = route;
      _resizable = resizable;
      _register();
    } else if (!_isRegistered) {
      // The element was reactivated after having been deactivated.
      _register();
    } else {
      // The route's isCurrent or isActive may have changed.
      _resizable!._handleStateChange();
    }
  }

  @override
  void deactivate() {
    // Unregistering here rather than in dispose() keeps the registry free of
    // routes whose content has already been detached from the tree, whose
    // render object can no longer be read.
    _unregister();
    super.deactivate();
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _RenderRouteContentBoundaryWidget(
      key: _boundaryKey,
      bypassedConstraints: context
          .dependOnInheritedWidgetOfExactType<_BypassedNavigatorConstraints>()!
          .value,
      child: widget.child,
    );

    return switch (Theme.of(context).platform) {
      TargetPlatform.android => _AnimationLessAndroidBackGestureHandler(
        child: result,
      ),
      _ => result,
    };
  }
}

/// A deprecated alias of [ResizableRouteContent].
@Deprecated('Use ResizableRouteContent instead.')
typedef ResizableNavigatorRouteContentBoundary = ResizableRouteContent;

/// Enables Android's predictive back gesture to pop routes within the
/// nested [Navigator], without modifying route transition progress during
/// the gesture.
///
/// This is a workaround for the issue where [TransitionRoute.animation]
/// jumps from a mid-transition value to 1.0 when the back gesture is committed,
/// causing an abrupt pop-transition animation.
///
/// The root cause is that [TransitionRoute.handleUpdateBackGestureProgress]
/// updates the [TransitionRoute.controller]'s value as the gesture progresses,
/// but [TransitionRoute.handleCommitBackGesture] triggers the transition
/// animation via [AnimationController.reverse] with 1.0 as the starting point,
/// regardless of the current [TransitionRoute.controller]'s value.
///
/// The default back gesture handler behaves this way, but is incompatible with
/// [NavigatorResizable]'s size transition. This handler therefore suppresses
/// gesture-driven transition progress while still allowing the gesture to
/// commit a route pop.
class _AnimationLessAndroidBackGestureHandler extends StatefulWidget {
  const _AnimationLessAndroidBackGestureHandler({
    required this.child,
  });

  final Widget child;

  @override
  State<_AnimationLessAndroidBackGestureHandler> createState() =>
      _AnimationLessAndroidBackGestureHandlerState();
}

class _AnimationLessAndroidBackGestureHandlerState
    extends State<_AnimationLessAndroidBackGestureHandler>
    with WidgetsBindingObserver {
  late ModalRoute<dynamic> _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context)!;
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    return !backEvent.isButtonEvent && _route.isCurrent && !_route.isFirst;
  }

  @override
  void handleCancelBackGesture() {
    _handleEndBackGesture(isCommitted: false);
  }

  @override
  void handleCommitBackGesture() {
    _handleEndBackGesture(isCommitted: true);
  }

  void _handleEndBackGesture({required bool isCommitted}) {
    if (isCommitted && _route.isCurrent) {
      _route.navigator?.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _RenderRouteContentBoundaryWidget extends SingleChildRenderObjectWidget {
  const _RenderRouteContentBoundaryWidget({
    super.key,
    required this.bypassedConstraints,
    required super.child,
  });

  final BoxConstraints bypassedConstraints;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRouteContentBoundary(
      bypassedConstraints: bypassedConstraints,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRouteContentBoundary).bypassedConstraints =
        bypassedConstraints;
  }
}

class _RenderRouteContentBoundary extends RenderShiftedBox {
  _RenderRouteContentBoundary({
    required this.bypassedConstraints,
  }) : super(null);

  BoxConstraints bypassedConstraints;

  /// A cache of the [child]'s [size] determined in the previous call
  /// to [performLayout]. This allows objects to read that value outside
  /// of the layout phase, which isn't permitted through the [size] getter.
  Size? lastMeasuredChildSize;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return switch (child) {
      null => Size.zero,
      final c => c.getDryLayout(constraints),
    };
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = lastMeasuredChildSize = Size.zero;
      return;
    }
    child.layout(bypassedConstraints, parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Offset.zero;
    // Make a copy to ensure the cached value is immutable.
    lastMeasuredChildSize = Size.copy(child.size);
    // The size of this object does not always equal the child's: with an
    // unbounded constraint, the navigator imposes a tight constraint on
    // routes other than the current one, requiring them to match the current
    // route's size, which may differ from the child's size laid out above.
    size = constraints.constrain(child.size);
  }
}

class _SizeProxyAnimation extends ChangeNotifier
    implements ValueListenable<Size?> {
  Animation<Size?>? get parent => _parent;
  Animation<Size?>? _parent;
  set parent(Animation<Size?>? animation) {
    _parent?.removeListener(notifyListeners);
    _parent = animation?..addListener(notifyListeners);
  }

  @override
  Size? get value => parent?.value;

  @override
  void dispose() {
    _parent?.removeListener(notifyListeners);
    _parent = null;
    super.dispose();
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

extension on Size {
  bool nearEqual(Size other) {
    return physics.nearEqual(
          height,
          other.height,
          Tolerance.defaultTolerance.distance,
        ) &&
        physics.nearEqual(
          width,
          other.width,
          Tolerance.defaultTolerance.distance,
        );
  }
}
