import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' as p;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';

import 'navigator_size_notifier.dart';
import 'route_transition_observer.dart';
import 'route_transition_status.dart';

class NavigatorResizable extends StatefulWidget
    with RouteTransitionAwareWidgetMixin {
  const NavigatorResizable({
    super.key,
    required this.transitionObserver,
    this.interpolationCurve = Curves.easeInOutCubic,
    required this.child,
  });

  final Curve interpolationCurve;
  final Widget child;

  @override
  final RouteTransitionObserver transitionObserver;

  @override
  State<NavigatorResizable> createState() => NavigatorResizableState();
}

@internal
class NavigatorResizableState extends State<NavigatorResizable>
    with RouteTransitionAwareStateMixin<NavigatorResizable> {
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

  @override
  void didChangeTransitionStatus(RouteTransitionStatus transition) {
    _preferredSizeNotifier.didChangeTransitionStatus(transition);
  }

  void didAddRoute(ModalRoute<dynamic> route) {
    _preferredSizeNotifier.addRoute(route);
  }

  void didRemoveRoute(ModalRoute<dynamic> route) {
    _preferredSizeNotifier.removeRoute(route);
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
