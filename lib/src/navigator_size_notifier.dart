import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'navigator_resizable.dart';

const _defaultPreferredSize = Size.infinite;

/// A snapshot of the geometry of a single route content, captured during
/// a layout pass of the [NavigatorResizable].
typedef RouteContentGeometry = ({
  /// The size of the route content, or `null` if it has not been laid out yet.
  Size? size,

  /// How much the route covers the routes below it, where 0 means the route
  /// is completely invisible and 1 means it is fully presented.
  ///
  /// This is the value of [TransitionRoute.animation].
  double transitionProgress,

  /// Whether the transition of the route is driven by a user gesture,
  /// typically a swipe back gesture.
  bool isUserGestureInProgress,
});

/// Computes the size that the navigator prefers to be, based on the sizes of
/// the route contents and how far their transitions have progressed.
@internal
class NavigatorSizeNotifier extends ChangeNotifier
    implements ValueListenable<Size> {
  NavigatorSizeNotifier({
    required this.interpolationCurve,
  });

  /// The curve used to interpolate between the sizes of two routes
  /// during a route transition.
  final Curve interpolationCurve;

  /// The size that the navigator prefers to be.
  ///
  /// This is [_defaultPreferredSize] until at least one route content
  /// reports its size, and retains the last computed size if all the route
  /// contents are gone.
  @override
  Size get value => _value ?? _defaultPreferredSize;
  Size? _value;

  /// Recomputes [value] from the given route contents, which must be ordered
  /// from the bottom-most route to the top-most one.
  ///
  /// The size is computed by interpolating the sizes of the route contents
  /// from the bottom to the top, using each route's transition progress as
  /// the interpolation ratio. For example, if there are two routes, `a` and
  /// `b`, and `b` is in the middle of its entrance transition, the resulting
  /// size is the size of `a` and `b` interpolated by the progress of `b`'s
  /// transition. As a result, the size always matches the size of the
  /// top-most route content when no transition is in progress.
  ///
  /// This method never notifies the listeners, since it is meant to be called
  /// during a layout pass, where notifying the listeners would immediately
  /// mark the navigator as needing layout again.
  void update(Iterable<RouteContentGeometry> contents) {
    var newValue = _value;
    for (final content in contents) {
      final size = content.size;
      if (size == null || !size.isFinite) {
        // The route content has not been laid out yet, so it is not
        // possible to take it into account.
        continue;
      }
      if (newValue == null) {
        newValue = size;
        continue;
      }
      final progress = content.transitionProgress.clamp(0.0, 1.0);
      newValue = Size.lerp(
        newValue,
        size,
        // The interpolation curve is not applied while the user is dragging
        // the route, since the size should exactly follow the gesture.
        content.isUserGestureInProgress
            ? progress
            : interpolationCurve.transform(progress),
      );
    }
    _value = newValue;
  }

  /// Requests the [NavigatorResizable] to recompute its size in the current
  /// frame.
  ///
  /// This must not be called during a layout pass;
  /// use [invalidateAfterLayout] instead.
  void invalidate() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Requests the [NavigatorResizable] to recompute its size in the next
  /// frame.
  ///
  /// Unlike [invalidate], this is safe to call during a layout pass, where it
  /// is too late to mark the [NavigatorResizable] as needing layout again.
  void invalidateAfterLayout() {
    if (_disposed || _isInvalidationScheduled) {
      return;
    }
    _isInvalidationScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _isInvalidationScheduled = false;
      invalidate();
    });
  }

  var _isInvalidationScheduled = false;
  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _value = null;
    super.dispose();
  }
}
