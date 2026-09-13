import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' as p;
import 'package:flutter/rendering.dart';

import 'navigator_event_observer.dart';
import 'navigator_size_notifier.dart';
import 'resizable_navigator_routes.dart';

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
/// The [NavigatorResizable] can respect the content size of a route
/// only if the route mix-ins the [ObservableRouteMixin] and its content
/// is wrapped in a [ResizableNavigatorRouteContentBoundary].
/// This is especially important during route transitions, as the
/// [NavigatorResizable] can animate its size in sync with the transition
/// animation only when both the current route and the next route satisfy
/// these requirements. Otherwise, the size remains unchanged before
/// and after the transition.
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
/// [ResizableNavigatorRouteContentBoundary] in [ModalRoute.buildPage].
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
/// - Avoid wrapping the navigator in widgets that add additional space
///   (e.g., [Padding]). Zero-size widgets, such as [GestureDetector]
///   or [InheritedWidget], are acceptable.
/// - Do not place [NavigatorResizable] inside a widget with a tight constraint,
///   as this forces [NavigatorResizable] to ignore the size of the current
///   route's content and adopt the size dictated by the constraints.
///   In such cases, an assertion error will be thrown. Typically, [Center]
///   and [Align] are good choices for the parent widget.
/// - The initial route of the [child] navigator must satisfy the requirements
///   of [NavigatorResizable]. Otherwise, [NavigatorResizable] will be unable
///   to determine the initial size and will throw an assertion error.
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

  /// The real, bounded constraints given to this widget by its parent.
  ///
  /// Updated by [_RenderNavigatorResizable] at the very start of every
  /// layout pass, before it lays out the child [Navigator] with unbounded
  /// constraints. Read by [_RenderRouteContentBoundary] so route content can
  /// be laid out against the real bounds instead of the unbounded ones
  /// flowing down from the Navigator, keeping `double.infinity`-based
  /// content resolving the same way it always has.
  BoxConstraints _routeContentConstraints = const BoxConstraints();

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
    return NavigatorEventObserver(
      listeners: [_preferredSizeNotifier],
      child: _InheritedNavigatorResizable(
        state: this,
        child: _RenderNavigatorResizableWidget(
          state: this,
          preferredSize: _preferredSizeNotifier,
          child: widget.child,
        ),
      ),
    );
  }

  void didRouteContentSizeChange(ModalRoute<dynamic> route, Size contentSize) {
    _preferredSizeNotifier.didRouteContentSizeChange(route, contentSize);
  }

  static _NavigatorResizableState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedNavigatorResizable>()!
        .state;
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
    required this.state,
    required this.preferredSize,
    required super.child,
  });

  final _NavigatorResizableState state;
  final NavigatorSizeNotifier preferredSize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderNavigatorResizable(
      state: state,
      preferredSize: preferredSize,
    );
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
    required _NavigatorResizableState state,
    required NavigatorSizeNotifier preferredSize,
  }) : _state = state,
       _preferredSize = preferredSize,
       super(
         alignment: Alignment.topLeft,
         textDirection: null,
       ) {
    preferredSize.addListener(markNeedsLayout);
  }

  final _NavigatorResizableState _state;

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
      _preferredSize.removeListener(markNeedsLayout);
      _preferredSize = value..addListener(markNeedsLayout);
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    assert(!_disposed);
    _preferredSize.removeListener(markNeedsLayout);
    _disposed = true;
    super.dispose();
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    // Mirrors performLayout's choice of size source, using a hypothetical
    // (non-committing) child layout in place of the real one performLayout
    // relies on.
    final preferredSize = _preferredSize.isTransitioning
        ? _preferredSize.value
        : child?.getDryLayout(const BoxConstraints()) ?? _preferredSize.value;
    return constraints.constrain(preferredSize);
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

    // Publish the real, bounded constraints so
    // ResizableNavigatorRouteContentBoundary can re-impose them on route
    // content below, since the Navigator itself is about to be laid out
    // with unbounded constraints instead.
    _state._routeContentConstraints = constraints;

    // Giving the Navigator unbounded constraints lets it shrink-wrap to the
    // current route's actual content size, which we can then read directly
    // below. This avoids the one-frame lag that results from going through
    // NavigatorSizeNotifier, whose value can only be updated in response to
    // a route content layout that already happened.
    child!.layout(const BoxConstraints(), parentUsesSize: true);

    // While a transition is in progress, the Navigator's own size merely
    // snaps to the incoming route rather than interpolating, so the
    // interpolated value from NavigatorSizeNotifier is still needed there.
    // Outside of a transition, the Navigator's own measured size is both
    // more accurate and available a frame earlier.
    final effectiveSize = _preferredSize.isTransitioning
        ? _preferredSize.value
        : child!.size;
    size = constraints.constrain(effectiveSize);
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

/// Observes the layout of the [child] widget and notifies the ancestor
/// [NavigatorResizable] when the child's size changes.
///
/// A route is compatible with [NavigatorResizable] only if it mixes-in
/// the [ObservableRouteMixin] and wraps its content in
/// a [ResizableNavigatorRouteContentBoundary]. For example, a subclass
/// of [ModalRoute] should return a [ResizableNavigatorRouteContentBoundary]
/// in [ModalRoute.buildPage].
///
/// It is rarely used directly. Instead, use the built-in route classes
/// that satisfy the requirements of [NavigatorResizable],
/// such as [ResizableMaterialPageRoute] and [ResizablePageRouteBuilder].
class ResizableNavigatorRouteContentBoundary
    extends SingleChildRenderObjectWidget {
  /// Creates a widget that observes the layout of the [child].
  const ResizableNavigatorRouteContentBoundary({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    final parentRoute = ModalRoute.of(context)!;
    final navigatorResizable = _NavigatorResizableState.of(context);
    return _RenderRouteContentBoundary(
      state: navigatorResizable,
      didRouteContentSizeChangeCallback: (size) {
        navigatorResizable.didRouteContentSizeChange(parentRoute, size);
      },
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final parentRoute = ModalRoute.of(context)!;
    final navigatorResizable = _NavigatorResizableState.of(context);
    (renderObject as _RenderRouteContentBoundary)
      ..state = navigatorResizable
      ..didRouteContentSizeChangeCallback = (size) {
        navigatorResizable.didRouteContentSizeChange(parentRoute, size);
      };
  }
}

/// Lays out [child] against the real, bounded constraints published by the
/// ancestor [_RenderNavigatorResizable] (via [_NavigatorResizableState]),
/// rather than the ambient constraints it's actually given here, which are
/// unbounded because the Navigator above it is laid out unbounded so it can
/// shrink-wrap to this content. This box in turn shrink-wraps to [child]'s
/// resulting size, so the Navigator's own measured size reflects it.
class _RenderRouteContentBoundary extends RenderShiftedBox {
  _RenderRouteContentBoundary({
    required _NavigatorResizableState state,
    required this.didRouteContentSizeChangeCallback,
  }) : _state = state,
       super(null);

  _NavigatorResizableState _state;
  // ignore: avoid_setters_without_getters
  set state(_NavigatorResizableState value) => _state = value;

  ValueSetter<Size> didRouteContentSizeChangeCallback;

  @override
  void performLayout() {
    final child = this.child;
    assert(child != null);
    child!.layout(_state._routeContentConstraints, parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Offset.zero;
    // This box's own size must still satisfy whatever ambient constraints
    // it was actually given (e.g. the Overlay forces non-topmost routes to
    // fill its resolved size exactly), even though the child above was laid
    // out against the real, stashed constraints instead.
    size = constraints.constrain(child.size);
    // Ensure the size object is immutable.
    didRouteContentSizeChangeCallback(Size.copy(child.size));
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
