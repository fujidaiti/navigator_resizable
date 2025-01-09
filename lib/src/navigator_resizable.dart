import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' as p;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';

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
/// only if the route mix-ins the [ObservableRouteMixin].
/// This is especially important during route transitions, as the
/// [NavigatorResizable] can animate its size in sync with the transition
/// animation only when both the current route and the next route
/// implement [ObservableRouteMixin]. Otherwise, the size
/// remains unchanged before and after the transition.
///
/// For convenience, the following built-in route classes already mix-in
/// the [ObservableRouteMixin]:
/// - [ResizableMaterialPageRoute]: A replacement for [MaterialPageRoute].
/// - [ResizableMaterialPage]: A replacement for [MaterialPage].
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
/// ### Caveats
/// - Avoid wrapping the navigator in widgets that add additional space
///   (e.g., [Padding]). Zero-size widgets, such as [GestureDetector]
///   or [InheritedWidget], are acceptable.
/// - Do not place [NavigatorResizable] inside a widget with a tight constraint,
///   as this forces [NavigatorResizable] to ignore the size of the current
///   route's content and adopt the size dictated by the constraints.
///   In such cases, an assertion error will be thrown. Typically, [Center]
///   and [Align] are good choices for the parent widget.
/// - The initial route of the [child] navigator must implement
///   [ObservableRouteMixin] (e.g., [ResizableMaterialPageRoute]),
///   otherwise, [NavigatorResizable] will be unable to determine the
///   initial size and will throw an assertion error.
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
/// [Navigator.pop], [named routes](https://api.flutter.dev/flutter/widgets/Navigator-class.html#:~:text=Using%20named%20navigator%20routes),
/// and the [Pages API](https://api.flutter.dev/flutter/widgets/Navigator-class.html#:~:text=the%20current%20page.-,Using%20the%20Pages%20API,-The%20Navigator%20will),
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
/// For more practical examples, refer to the
/// [/example](https://github.com/fujidaiti/resizable_navigator/tree/main/example/lib) directory.
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
  State<NavigatorResizable> createState() => NavigatorResizableState();
}

@internal
class NavigatorResizableState extends State<NavigatorResizable> {
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
    return NavigatorEventObserver(
      listeners: [_preferredSizeNotifier],
      child: _InheritedNavigatorResizable(
        state: this,
        child: _RenderNavigatorResizableWidget(
          preferredSize: _preferredSizeNotifier,
          child: widget.child,
        ),
      ),
    );
  }

  void didRouteContentSizeChange(ModalRoute<dynamic> route, Size contentSize) {
    _preferredSizeNotifier.didRouteContentSizeChange(route, contentSize);
  }

  static NavigatorResizableState of(BuildContext context) {
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

  final NavigatorResizableState state;

  @override
  bool updateShouldNotify(_InheritedNavigatorResizable oldWidget) => true;
}

class _RenderNavigatorResizableWidget extends SingleChildRenderObjectWidget {
  const _RenderNavigatorResizableWidget({
    required this.preferredSize,
    required super.child,
  });

  final ValueListenable<Size> preferredSize;

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
    required ValueListenable<Size> preferredSize,
  })  : _preferredSize = preferredSize,
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

  ValueListenable<Size> _preferredSize;
  // ignore: avoid_setters_without_getters
  set preferredSize(ValueListenable<Size> value) {
    if (value != _preferredSize) {
      _preferredSize.removeListener(_onPreferredSizeChanged);
      _preferredSize = value..addListener(_onPreferredSizeChanged);
    }
  }

  void _onPreferredSizeChanged() {
    switch (SchedulerBinding.instance.schedulerPhase) {
      // If the change is triggered during the layout phase,
      // it's too late to apply the new size to this render box
      // in the current frame. Instead, we schedule a new frame
      // to ensure the new size is eventually applied in the
      // following frame.
      case SchedulerPhase.persistentCallbacks:
        SchedulerBinding.instance.scheduleFrameCallback((_) {
          if (!_disposed) markNeedsLayout();
        });
      // Otherwise, schedule a layout immediately.
      case _:
        markNeedsLayout();
    }
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

    // Pass the parent constraints directly to the child Navigator,
    // allowing it to overflow this render box if necessary.
    child!.layout(constraints, parentUsesSize: true);
    size = computeDryLayout(constraints);
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

@internal
class ResizableNavigatorRouteContentBoundary
    extends SingleChildRenderObjectWidget {
  const ResizableNavigatorRouteContentBoundary({
    super.key,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    final parentRoute = ModalRoute.of(context)!;
    final navigatorResizable = NavigatorResizableState.of(context);
    return _RenderRouteContentBoundary(
      didRouteContentSizeChangeCallback: (size) {
        navigatorResizable.didRouteContentSizeChange(parentRoute, size);
      },
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final parentRoute = ModalRoute.of(context)!;
    final navigatorResizable = NavigatorResizableState.of(context);
    (renderObject as _RenderRouteContentBoundary)
        .didRouteContentSizeChangeCallback = (size) {
      navigatorResizable.didRouteContentSizeChange(parentRoute, size);
    };
  }
}

class _RenderRouteContentBoundary extends RenderPositionedBox {
  _RenderRouteContentBoundary({
    required this.didRouteContentSizeChangeCallback,
  }) : super(alignment: Alignment.topLeft);

  ValueSetter<Size> didRouteContentSizeChangeCallback;

  @override
  void performLayout() {
    super.performLayout();
    if (child?.size case final childSize?) {
      didRouteContentSizeChangeCallback(
        // Ensure the size object is immutable.
        Size.copy(childSize),
      );
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
