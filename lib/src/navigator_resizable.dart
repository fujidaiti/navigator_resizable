import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' as physics;
import 'package:flutter/rendering.dart';

import 'navigator_event_observer.dart';
import 'resizable_navigator_routes.dart';

/// A widget that resizes the child [Navigator] to match the intrinsic size of
/// the current [Route]'s content.
///
/// Think of this like a resizable box with nested pages, whose size changes as
/// the current page goes from one to another. If the first page wants to be
/// 200x200, this widget has that size. If the second page wants to be 400x400
/// and the users go to the second page, this widget then becomes a 400x400 box.
///
/// Technically, this widget lets the top-level widget hosted by the navigator's
/// current route freely determine its width and height, and sizes the navigator
/// and itself to match that dimensions.
///
/// During route transitions, this widget gradually grows or shrinks toward the
/// next route's size along with the transition animation, instead of changing
/// abruptly. Note that, however, the navigator keeps its previous size during
/// the transition and jumps to the target size when it completes. That is, the
/// navigator may be bigger or smaller than this widget's boundoary box while
/// transitioning, and the overflowed portions, if any, are visually clipped.
///
/// ### Routes and Pages
///
/// The [NavigatorResizable] can respect the content size of a route
/// only if the route mix-ins the [ObservableRouteMixin] and its content
/// is wrapped in a [ResizableNavigatorRouteContentBoundary].
/// This is especially important during route transitions, as the
/// [NavigatorResizable] can animate its size in sync with the transition
/// animation only when both the current route and the next route satisfy
/// those requirements. Otherwise, the navigator's size changes abruplty
/// without any animation.
///
/// For convenience, the following built-in route and page classes are provided,
/// all of which satisfy the requirements of [NavigatorResizable]:
///
/// - [ResizableMaterialPageRoute]: A replacement for [MaterialPageRoute].
/// - [ResizableMaterialPage]: A replacement for [MaterialPage].
/// - [ResizablePageRouteBuilder]: A replacement for [PageRouteBuilder].
/// - [ResizablePageRoutePageBuilder]: Similar to [ResizablePageRouteBuilder],
///   but creates a [Page].
///
/// Note that the [child] navigator and its routes are constrained by the
/// constraints imposed by the parent widget of the [NavigatorResizable].
/// To ensure that the route content fills the entire available space,
/// the easiest way is to set the content widget's width or height
/// to [double.infinity].
///
/// ```dart
/// ResizableMaterialPageRoute(
///   builder: (context) {
///     return Container(
///       color: Colors.while,
///       width: double.infinity,
///       height: double.infinity,
///     );
///   },
/// );
/// ```
///
/// For more advanced use cases, you can create a custom route
/// compatible with [NavigatorResizable] by mixing in
/// the [ObservableRouteMixin] and returning a
/// [_RenderRouteContentBoundaryWidget] in [ModalRoute.buildPage].
///
/// ```dart
/// class CustomResizableRoute<T> extends ModalRoute<T>
///   with ObservableRouteMixin<T>{
///   CustomResizableRoute({
///     required super.builder,
///     ...
///   });
///
///   @override
///   Widget buildContent(BuildContext context) {
///     return ResizableNavigatorRouteContentBoundary(
///       child: builder(context),
///     );
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
/// Otherwise it adopt the size enforced by the constraints, ignoreing the size
/// of current route's content. Typically, [Center] and [Align] are good choices
/// for the parent widget.
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
///   ResizableMaterialPageRoute(
///     builder: (context) {
///       return Container(
///         color: Colors.red,
///         width: 300,
///         height: 300,
///       );
///     },
///   ),
/// );
/// ```
///
/// See [/example][3] directory for more practical examples.
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
  /// This is not necessary to be a raw [Navigator]. A navigator wrapped with
  /// zero-sized widgets, such as [GestureDetector] and [ColoredBox], or widgets
  /// without render objects, such as [Theme] and [AnimatedBuilder], are all
  /// acceptable.
  final Widget child;

  @override
  State<NavigatorResizable> createState() => _NavigatorResizableState();
}

class _NavigatorResizableState extends State<NavigatorResizable>
    with NavigatorEventListener {
  /// Represents an interpolated size of the navigator during a transition.
  /// The value is available only when the transition is running, otherwise
  /// reports null.
  late final _SizeProxyAnimation _sizeInterpolation;

  Route<dynamic>? _lastSettledRoute;

  @override
  void initState() {
    super.initState();
    _sizeInterpolation = _SizeProxyAnimation();
  }

  @override
  void dispose() {
    _sizeInterpolation.dispose();
    super.dispose();
  }

  @override
  VoidCallback? didInstall(Route<dynamic> route) {
    void onDispose() {
      if (route == _lastSettledRoute) {
        _lastSettledRoute = null;
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
    if (isUserGestureInProgress) {
      _startUserGestureTransition(targetRoute, animation);
    } else if (animation.status == AnimationStatus.forward) {
      _startPushTransition(targetRoute, animation);
    } else {
      assert(animation.status == AnimationStatus.reverse);
      _startPopTransition(targetRoute, animation);
    }
  }

  void _startUserGestureTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation,
  ) {
    assert(animation.isForwardOrCompleted);
    final initialSize =
        _sizeInterpolation.value ??
        ResizableNavigatorRouteContentBoundary._sizeFor(_lastSettledRoute);
    _sizeInterpolation.parent = _LazySizeTween(
      start: () => ResizableNavigatorRouteContentBoundary._sizeFor(targetRoute),
      end: () => initialSize,
    ).animate(animation);
  }

  void _startPushTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation,
  ) {
    assert(animation.isForwardOrCompleted);
    final initialSize =
        _sizeInterpolation.value ??
        ResizableNavigatorRouteContentBoundary._sizeFor(_lastSettledRoute);
    _sizeInterpolation.parent = _LazySizeTween(
      start: () => initialSize,
      end: () => ResizableNavigatorRouteContentBoundary._sizeFor(targetRoute),
    ).chain(CurveTween(curve: widget.interpolationCurve)).animate(animation);
  }

  void _startPopTransition(
    Route<dynamic> targetRoute,
    Animation<double> animation,
  ) {
    assert(!animation.isForwardOrCompleted);
    final initialSize =
        _sizeInterpolation.value ??
        ResizableNavigatorRouteContentBoundary._sizeFor(_lastSettledRoute);

    Size? targetRouteSize() {
      return ResizableNavigatorRouteContentBoundary._sizeFor(targetRoute);
    }

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

  @override
  void didEndTransition(Route<dynamic> route) {
    _lastSettledRoute = route;
    _sizeInterpolation.parent = null;
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorEventObserver(
      listeners: [this],
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
      'The NavigatorResizable widget was given an tight constraint. '
      'This is not allowed because it needs to size itself to fit '
      'the current route content. Consider wrapping the NavigatorResizable '
      'with a widget that provides non-tight constraints, such as Align '
      'and Center.\n'
      'The given constraints were: $constraints which was given by '
      'the parent: ${parent?.parent.runtimeType}',
      // We refer to parent.parent here as the parent is always the render
      // object for the LayoutBuilder that the NavigatorResizable builds
      // internally, which isn't what developers insert by themselves.
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
      'The given constraints were $constraints, which was given by '
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

/// This widget is supposed to be the outermost parent of the [Route]'s content
/// hosted by the [Navigator] under a [NavigatorResizable].
///
/// This is rarely used directly. Instead, use built-in route classes that
/// satisfy the above requirements, such as [ResizableMaterialPageRoute]
/// and [ResizablePageRouteBuilder].
class ResizableNavigatorRouteContentBoundary extends StatelessWidget {
  const ResizableNavigatorRouteContentBoundary({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _RenderRouteContentBoundaryWidget(
      key: _globalKeyFor(ModalRoute.of(context)),
      bypassedConstraints: context
          .dependOnInheritedWidgetOfExactType<_BypassedNavigatorConstraints>()!
          .value,
      child: child,
    );
  }

  static final _globalKeyRegistry = Expando<GlobalKey>('boundaryKetRegistry');

  static GlobalKey? _globalKeyFor(Route<dynamic>? route) {
    if (route == null) {
      return null;
    }
    return _globalKeyRegistry[route] ??= GlobalKey();
  }

  static Size? _sizeFor(Route<dynamic>? route) {
    final key = _globalKeyFor(route);
    final element = (key?.currentContext as SingleChildRenderObjectElement?);
    final renderObj = (element?.renderObject as _RenderRouteContentBoundary?);
    return renderObj?.lastMeasuredChildSize;
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

  Size _computeLayout(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) layoutChild,
  ) {
    return switch (child) {
      null => Size.zero,
      final child => layoutChild(child, constraints),
    };
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return _computeLayout(
      constraints,
      (child, cons) => child.getDryLayout(cons),
    );
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
