import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' as p;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'navigator_size_notifier.dart';

/// A thin wrapper around [Navigator] that **visually** resizes the [child]
/// navigator to match the size of the content displayed in the current route.
///
/// This widget is functionally similar to combining [OverflowBox] and
/// [ClipRect], but it is specifically designed for this use case.
/// It adjusts its size, hit test area, and painting area to align
/// with the size of the widget displayed by the [child] navigator's
/// current route. The navigator itself can overflow this widget,
/// maintaining its size as determined by the parent constraints
/// unless those constraints change. This helps minimize unnecessary
/// layout operations for the navigator and its routes.
///
/// ### Routes and Pages
///
/// Any kind of route can be used with the [child] navigator, such as
/// [MaterialPageRoute] and [PageRouteBuilder]. The only requirement is that
/// the content of each route is wrapped in
/// a [ResizableNavigatorRouteContentBoundary], which tells this widget
/// the size that the route content wants to be.
///
/// ```dart
/// MaterialPageRoute(
///   builder: (context) {
///     return const ResizableNavigatorRouteContentBoundary(
///       child: MyRouteContent(),
///     );
///   },
/// );
/// ```
///
/// A route without a [ResizableNavigatorRouteContentBoundary] is simply
/// ignored, in which case the size of this widget remains unchanged
/// while that route is on top of the navigation stack.
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
///     return const ResizableNavigatorRouteContentBoundary(
///       child: SizedBox(
///         width: double.infinity,
///         height: double.infinity,
///       ),
///     );
///   },
/// );
/// ```
///
/// ### Caveats
/// - Avoid wrapping the navigator in widgets that add additional space
///   (e.g., [Padding]). Zero-size widgets, such as [GestureDetector]
///   or [InheritedWidget], are acceptable.
/// - Do not place [NavigatorResizable] inside a widget with a tight constraint,
///   as this forces [NavigatorResizable] to ignore the size of the current
///   route's content and adopt the size dictated by the constraints.
///   In such cases, an assertion error will be thrown. Typically, [Center]
///   and [Align] are good choices for the parent widget.
/// - The initial route of the [child] navigator should have
///   a [ResizableNavigatorRouteContentBoundary]. Otherwise,
///   [NavigatorResizable] will be unable to determine the initial size
///   and will expand to the maximum size allowed by the parent constraints.
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
///       return const ResizableNavigatorRouteContentBoundary(
///         child: SizedBox(width: 300, height: 300),
///       );
///     },
///   ),
/// );
/// ```
///
/// For more practical examples, refer to the [/example][3] directory.
///
/// [1]: https://api.flutter.dev/flutter/widgets/Navigator-class.html#:~:text=Using%20named%20navigator%20routes
/// [2]: https://api.flutter.dev/flutter/widgets/Navigator-class.html#:~:text=the%20current%20page.-,Using%20the%20Pages%20API,-The%20Navigator%20will
/// [3]: https://github.com/fujidaiti/navigator_resizable/tree/main/example/lib
class NavigatorResizable extends StatefulWidget {
  /// Creates a thin wrapper around [Navigator] that **visually** resizes
  /// the [child] navigator to match the size of the content displayed
  /// in the current route.
  const NavigatorResizable({
    super.key,
    this.interpolationCurve = Curves.easeInOutCubic,
    required this.child,
  });

  /// The [Curve] used for interpolating the size of this widget
  /// during a route transition animation.
  ///
  /// This widget gradually changes its size during a route transition,
  /// interpolating between the sizes of the previous and the next route
  /// with this curve. The default value is [Curves.easeInOutCubic].
  final Curve interpolationCurve;

  /// The [Navigator] for which the visual resizing should be applied.
  final Widget child;

  @override
  State<NavigatorResizable> createState() => _NavigatorResizableState();
}

class _NavigatorResizableState extends State<NavigatorResizable> {
  late final NavigatorSizeNotifier _preferredSizeNotifier;

  @override
  void initState() {
    super.initState();
    _preferredSizeNotifier = NavigatorSizeNotifier(
      interpolationCurve: widget.interpolationCurve,
    );
  }

  @override
  void dispose() {
    _preferredSizeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedNavigatorResizable(
      state: this,
      child: _RenderNavigatorResizableWidget(
        preferredSize: _preferredSizeNotifier,
        child: widget.child,
      ),
    );
  }

  static _NavigatorResizableState of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedNavigatorResizable>();
    assert(
      result != null,
      'No NavigatorResizable found in the widget tree. '
      'ResizableNavigatorRouteContentBoundary can only be used in a route '
      'of a Navigator that is wrapped in a NavigatorResizable.',
    );
    return result!.state;
  }
}

/// Provides a direct access to the state of the ancestor [NavigatorResizable]
/// for the descendant [ResizableNavigatorRouteContentBoundary] widgets.
class _InheritedNavigatorResizable extends InheritedWidget {
  const _InheritedNavigatorResizable({
    required this.state,
    required super.child,
  });

  final _NavigatorResizableState state;

  @override
  bool updateShouldNotify(_InheritedNavigatorResizable oldWidget) => true;
}

class _RenderNavigatorResizableWidget extends SingleChildRenderObjectWidget {
  const _RenderNavigatorResizableWidget({
    required this.preferredSize,
    required super.child,
  });

  final NavigatorSizeNotifier preferredSize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderNavigatorResizable(preferredSize: preferredSize);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderNavigatorResizable renderObject,
  ) {
    renderObject.preferredSize = preferredSize;
  }
}

class _RenderNavigatorResizable extends RenderAligningShiftedBox {
  _RenderNavigatorResizable({
    required NavigatorSizeNotifier preferredSize,
  }) : _preferredSize = preferredSize,
       super(
         alignment: Alignment.topLeft,
         textDirection: null,
       ) {
    preferredSize.addListener(_onPreferredSizeChanged);
  }

  @override
  bool get sizedByParent => false;

  /// The visible area of the descendant Navigator.
  ///
  /// Used in [paint] and [hitTest].
  /// The size of this rect should be kept in sync with the value of
  /// [_preferredSize] and the offset should be always [Offset.zero].
  late Rect _visibleBounds;

  NavigatorSizeNotifier _preferredSize;
  // ignore: avoid_setters_without_getters
  set preferredSize(NavigatorSizeNotifier value) {
    if (value != _preferredSize) {
      _preferredSize.removeListener(_onPreferredSizeChanged);
      _preferredSize = value..addListener(_onPreferredSizeChanged);
      markNeedsLayout();
    }
  }

  void _onPreferredSizeChanged() {
    markNeedsLayout();
  }

  bool _disposed = false;

  @override
  void dispose() {
    assert(!_disposed);
    _preferredSize.removeListener(_onPreferredSizeChanged);
    _disposed = true;
    super.dispose();
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return constraints.constrain(_preferredSize.value);
  }

  @override
  void performLayout() {
    assert(child != null);
    assert(
      !constraints.isTight,
      'The NavigatorResizable widget was given an tight constraint. '
      'This is not allowed because it needs to size itself to fit '
      'the current route content. Consider wrapping the NavigatorResizable '
      'with a widget that provides non-tight constraints, such as Align '
      'and Center. \n'
      'The given constraints were: $constraints which was given by '
      'the parent: ${parent.runtimeType}',
    );
    assert(
      constraints.hasBoundedHeight && constraints.hasBoundedWidth,
      'The NavigatorResizable widget was given unbounded constraints. '
      'This is not allowed because otherwise the routes within the underlying '
      'Navigator would not know their valid maximum size. This becomes '
      'especially problematic when a route specifies double.infinity for width '
      'or height to expand to the available space, which causes a layout error '
      'since the parent Navigator does not provide finite bounds.\n'
      'Make sure that NavigatorResizable is not wrapped in a widget that '
      'passes unbounded constraints to its children, such as Column or Row. '
      'The given constraints were:\n'
      '$constraints (from parent: ${parent.runtimeType}).',
    );

    // Pass the parent constraints directly to the child Navigator,
    // allowing it to overflow this render box if necessary.
    // This also ensures that the route contents are laid out before
    // their geometries are collected below.
    child!.layout(constraints, parentUsesSize: true);
    _preferredSize.update(_collectRouteContentGeometries());
    size = computeDryLayout(constraints);
    _visibleBounds = Offset.zero & size;
    alignChild();
  }

  /// Collects the geometries of the route contents in the descendant
  /// Navigator, ordered from the bottom-most route to the top-most one.
  ///
  /// The route contents are discovered by walking down the render tree, since
  /// the paint order of the routes in the navigator's [Overlay] is always
  /// the same as their order in the navigation stack.
  List<RouteContentGeometry> _collectRouteContentGeometries() {
    final result = <RouteContentGeometry>[];
    void visit(RenderObject node) {
      switch (node) {
        case final _RenderRouteContentBoundary boundary:
          result.add(boundary.geometry);
        // Do not descend into a nested NavigatorResizable, as the route
        // contents below it belong to another navigator.
        case _RenderNavigatorResizable():
          break;
        case _:
          node.visitChildren(visit);
      }
    }

    visitChildren(visit);
    return result;
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

/// Marks the content of a route as the region that the ancestor
/// [NavigatorResizable] should size itself to.
///
/// Wrap the content of every route in the navigator with this widget:
///
/// ```dart
/// MaterialPageRoute(
///   builder: (context) {
///     return const ResizableNavigatorRouteContentBoundary(
///       child: MyRouteContent(),
///     );
///   },
/// );
/// ```
///
/// This widget observes the layout of the [child] and the transition
/// animation of the enclosing route, and notifies the ancestor
/// [NavigatorResizable] when either of them changes.
///
/// A route without this widget is invisible to the [NavigatorResizable];
/// the size of the navigator remains unchanged while such a route is
/// the top-most route in the navigation stack.
class ResizableNavigatorRouteContentBoundary extends StatefulWidget {
  /// Creates a widget that marks the [child] as the content of a route.
  const ResizableNavigatorRouteContentBoundary({
    super.key,
    required this.child,
  });

  /// The content of the enclosing route.
  final Widget child;

  @override
  State<ResizableNavigatorRouteContentBoundary> createState() =>
      _ResizableNavigatorRouteContentBoundaryState();
}

class _ResizableNavigatorRouteContentBoundaryState
    extends State<ResizableNavigatorRouteContentBoundary>
    with WidgetsBindingObserver {
  late ModalRoute<dynamic> _route;
  late NavigatorSizeNotifier _preferredSizeNotifier;
  Animation<double>? _transitionProgress;

  @override
  void initState() {
    super.initState();
    // Registered to handle Android's predictive back gesture.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    assert(
      route != null,
      'ResizableNavigatorRouteContentBoundary must be placed '
      'in the content of a ModalRoute.',
    );

    _route = route!;
    _preferredSizeNotifier = _NavigatorResizableState.of(
      context,
    )._preferredSizeNotifier;

    if (_route.animation != _transitionProgress) {
      _transitionProgress?.removeListener(_onTransitionProgressChanged);
      _transitionProgress = _route.animation
        ?..addListener(_onTransitionProgressChanged);
    }

    // The set of the route contents in the navigator has changed,
    // so the preferred size of the navigator may also have changed.
    _preferredSizeNotifier.invalidate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transitionProgress?.removeListener(_onTransitionProgressChanged);
    _transitionProgress = null;
    // This widget is being removed from the tree along with the route content,
    // which changes the preferred size of the navigator.
    _preferredSizeNotifier.invalidate();
    super.dispose();
  }

  void _onTransitionProgressChanged() {
    if (_backGestureProgressFloor case final floor?
        when !_isBackGestureInProgress &&
            (_route.animation?.value ?? 1.0) >= floor) {
      // The transition progress has caught up with the value suppressed
      // during the back gesture, so the suppression is no longer needed.
      _backGestureProgressFloor = null;
    }
    _preferredSizeNotifier.invalidate();
  }

  /// How much the route covers the routes below it, where 0 means the route
  /// is completely invisible and 1 means it is fully presented.
  double get transitionProgress {
    // During the first frame of a route's entrance transition, the route is
    // built with `offstage=true` and an animation progress value of 1.0.
    // This causes a discontinuity in the animation progress, as the route
    // visually appears inactive but is technically at the end of the
    // animation. To address this, the progress is treated as 0.0 while
    // the route is offstage.
    if (_route.offstage) {
      return 0;
    }
    final progress = _route.animation?.value ?? 1.0;
    return switch (_backGestureProgressFloor) {
      null => progress,
      final floor => max(progress, floor),
    };
  }

  /// Whether the transition of the route is driven by a user gesture,
  /// typically a swipe back gesture.
  bool get isUserGestureInProgress =>
      _route.navigator?.userGestureInProgress ?? false;

  // Begin the Android predictive back gesture handling.
  //
  // While a predictive back gesture is in progress,
  // TransitionRoute.handleUpdateBackGestureProgress decreases the transition
  // progress of the route as the gesture proceeds, but
  // TransitionRoute.handleCommitBackGesture restarts the pop transition from
  // 1.0 regardless of the progress made during the gesture. Following the
  // progress would therefore cause an abrupt size change when the gesture is
  // committed. To avoid this, the transition progress reported to the
  // NavigatorResizable is not allowed to go below the value at which
  // the gesture started.

  /// The lower bound of the reported [transitionProgress], or `null` if
  /// no predictive back gesture has to be compensated for.
  double? _backGestureProgressFloor;

  var _isBackGestureInProgress = false;

  /// Whether the route itself, rather than this widget, is responsible for
  /// popping the route when the gesture is committed.
  ///
  /// This is the case when the route is built with a page transitions builder
  /// that supports the predictive back gesture, such as
  /// [PredictiveBackPageTransitionsBuilder].
  var _isBackGestureHandledByRoute = false;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !_route.isCurrent || _route.isFirst) {
      return false;
    }

    // The route's own handler, if any, is notified before this one, since it
    // is registered earlier as an ancestor of this widget. Therefore, if the
    // navigator is already in a user gesture, the route has claimed
    // the gesture and drives its transition animation by itself.
    _isBackGestureHandledByRoute = isUserGestureInProgress;
    _isBackGestureInProgress = true;
    _backGestureProgressFloor = _route.animation?.value ?? 1.0;
    _preferredSizeNotifier.invalidate();
    return true;
  }

  @override
  void handleCommitBackGesture() {
    _isBackGestureInProgress = false;
    // The pop transition restarts from the progress at which the gesture
    // started, so there is nothing to compensate for anymore.
    _backGestureProgressFloor = null;
    if (!_isBackGestureHandledByRoute && _route.isCurrent) {
      _route.navigator?.pop();
    }
    _preferredSizeNotifier.invalidate();
  }

  @override
  void handleCancelBackGesture() {
    // The suppression is kept until the transition progress animates back to
    // the value at which the gesture started; see _onTransitionProgressChanged.
    _isBackGestureInProgress = false;
    _onTransitionProgressChanged();
  }

  // End the Android predictive back gesture handling.

  @override
  Widget build(BuildContext context) {
    return _RouteContentBoundary(
      state: this,
      preferredSizeNotifier: _preferredSizeNotifier,
      child: widget.child,
    );
  }
}

class _RouteContentBoundary extends SingleChildRenderObjectWidget {
  const _RouteContentBoundary({
    required this.state,
    required this.preferredSizeNotifier,
    required super.child,
  });

  final _ResizableNavigatorRouteContentBoundaryState state;
  final NavigatorSizeNotifier preferredSizeNotifier;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRouteContentBoundary(
      state: state,
      preferredSizeNotifier: preferredSizeNotifier,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderRouteContentBoundary renderObject,
  ) {
    renderObject
      ..state = state
      ..preferredSizeNotifier = preferredSizeNotifier;
  }
}

class _RenderRouteContentBoundary extends RenderPositionedBox {
  _RenderRouteContentBoundary({
    required _ResizableNavigatorRouteContentBoundaryState state,
    required NavigatorSizeNotifier preferredSizeNotifier,
  }) : _state = state,
       _preferredSizeNotifier = preferredSizeNotifier,
       super(alignment: Alignment.topLeft);

  _ResizableNavigatorRouteContentBoundaryState _state;
  // ignore: avoid_setters_without_getters
  set state(_ResizableNavigatorRouteContentBoundaryState value) {
    if (value != _state) {
      _state = value;
      _preferredSizeNotifier.invalidate();
    }
  }

  NavigatorSizeNotifier _preferredSizeNotifier;
  // ignore: avoid_setters_without_getters
  set preferredSizeNotifier(NavigatorSizeNotifier value) {
    if (value != _preferredSizeNotifier) {
      _preferredSizeNotifier = value..invalidate();
    }
  }

  Size? _contentSize;

  /// The geometry of the route content, read by the ancestor
  /// [_RenderNavigatorResizable] during its layout.
  RouteContentGeometry get geometry => (
    size: _contentSize,
    transitionProgress: _state.transitionProgress,
    isUserGestureInProgress: _state.isUserGestureInProgress,
  );

  @override
  void performLayout() {
    super.performLayout();
    if (child?.size case final childSize? when childSize != _contentSize) {
      // Ensure the size object is immutable.
      _contentSize = Size.copy(childSize);
      // It is too late to change the size of the ancestor NavigatorResizable
      // in this frame, as it may have already been laid out.
      _preferredSizeNotifier.invalidateAfterLayout();
    }
  }
}

extension _SizeEquality on Size {
  bool nearEqual(Size other) {
    return p.nearEqual(
          height,
          other.height,
          Tolerance.defaultTolerance.distance,
        ) &&
        p.nearEqual(
          width,
          other.width,
          Tolerance.defaultTolerance.distance,
        );
  }
}
