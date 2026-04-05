import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navigator_event_observer.dart';
import 'navigator_resizable.dart';

abstract class _BaseResizableMaterialPageRoute<T> extends PageRoute<T>
    with ObservableRouteMixin<T>, MaterialRouteTransitionMixin<T> {
  _BaseResizableMaterialPageRoute({
    super.settings,
    super.requestFocus,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
  });

  Widget _buildContentInternal(BuildContext context);

  @override
  Widget buildContent(BuildContext context) {
    final result = ResizableNavigatorRouteContentBoundary(
      child: _buildContentInternal(context),
    );
    return switch (Theme.of(context).platform) {
      TargetPlatform.android => _AnimationLessAndroidBackGestureHandler(
        child: result,
      ),
      _ => result,
    };
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return switch (Theme.of(context).platform) {
      // PredictiveBackFullscreenPageTransitionsBuilder is incompatible with
      // NavigatorResizable's size transition, so we use the older
      // FadeForwardsPageTransitionsBuilder for Android instead.
      TargetPlatform.android =>
        const FadeForwardsPageTransitionsBuilder().buildTransitions(
          this,
          context,
          animation,
          secondaryAnimation,
          child,
        ),
      _ => super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      ),
    };
  }
}

/// A specialized [MaterialPageRoute] compatible with [NavigatorResizable].
///
/// For a detailed explanation of each property, see [MaterialPageRoute].
@optionalTypeArgs
class ResizableMaterialPageRoute<T> extends _BaseResizableMaterialPageRoute<T> {
  /// Creates a [MaterialPageRoute] compatible with [NavigatorResizable].
  ResizableMaterialPageRoute({
    required this.builder,
    super.settings,
    super.requestFocus,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
    this.maintainState = true,
  });

  @override
  final bool maintainState;

  /// Builds the primary contents of the route.
  final WidgetBuilder builder;

  @override
  Widget _buildContentInternal(BuildContext context) {
    return builder(context);
  }
}

/// A specialized [MaterialPage] compatible with [NavigatorResizable].
///
/// For a detailed explanation of each property, see [MaterialPage].
@optionalTypeArgs
class ResizableMaterialPage<T> extends MaterialPage<T> {
  /// Creates a [MaterialPage] compatible with [NavigatorResizable].
  const ResizableMaterialPage({
    super.key,
    super.canPop,
    super.onPopInvoked,
    super.name,
    super.arguments,
    super.restorationId,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
    required super.child,
  });

  @override
  Route<T> createRoute(BuildContext context) =>
      _PageBasedResizableMaterialPageRoute<T>(
        page: this,
        allowSnapshotting: allowSnapshotting,
      );
}

class _PageBasedResizableMaterialPageRoute<T>
    extends _BaseResizableMaterialPageRoute<T> {
  _PageBasedResizableMaterialPageRoute({
    required ResizableMaterialPage<T> page,
    required super.allowSnapshotting,
  }) : super(settings: page);

  ResizableMaterialPage<T> get page =>
      super.settings as ResizableMaterialPage<T>;

  @override
  bool get maintainState => page.maintainState;

  @override
  bool get fullscreenDialog => page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${page.name})';

  @override
  Widget _buildContentInternal(BuildContext context) {
    return page.child;
  }
}

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
    return !backEvent.isButtonEvent && _route.isCurrent;
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

/// A utility class for defining one-off [PageRoute]s in terms of callbacks.
///
/// Almost identical to [PageRouteBuilder] but specialized for compatibility
/// with [NavigatorResizable].
@optionalTypeArgs
class ResizablePageRouteBuilder<T> extends PageRoute<T>
    with ObservableRouteMixin<T> {
  /// Creates a route that delegates to builder callbacks.
  ResizablePageRouteBuilder({
    super.settings,
    super.requestFocus,
    required this.pageBuilder,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    super.fullscreenDialog,
    super.allowSnapshotting = true,
  });

  /// Used build the route's primary contents.
  ///
  /// See [ModalRoute.buildPage] for complete definition of the parameters.
  final RoutePageBuilder pageBuilder;

  /// Used to build the route's transitions.
  ///
  /// See [ModalRoute.buildTransitions] for complete definition
  /// of the parameters.
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  final bool opaque;

  @override
  final bool barrierDismissible;

  @override
  final Color? barrierColor;

  @override
  final String? barrierLabel;

  @override
  final bool maintainState;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ResizableNavigatorRouteContentBoundary(
      child: pageBuilder(context, animation, secondaryAnimation),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionsBuilder(context, animation, secondaryAnimation, child);
  }
}

/// A utility class for defining one-off [Page] that creates [PageRoute]
/// in terms of callbacks.
///
/// Intended to be used with [NavigatorResizable].
@optionalTypeArgs
class ResizablePageRoutePageBuilder<T> extends Page<T> {
  /// Creates a page that delegates to builder callbacks.
  const ResizablePageRoutePageBuilder({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    required this.child,
    required this.transitionsBuilder,
    this.requestFocus = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
  });

  /// See [PageRouteBuilder.transitionsBuilder].
  final RouteTransitionsBuilder transitionsBuilder;

  /// See [PageRouteBuilder.requestFocus].
  final bool? requestFocus;

  /// See [PageRouteBuilder.transitionDuration].
  final Duration transitionDuration;

  /// See [PageRouteBuilder.reverseTransitionDuration].
  final Duration reverseTransitionDuration;

  /// See [PageRouteBuilder.opaque].
  final bool opaque;

  /// See [PageRouteBuilder.barrierDismissible].
  final bool barrierDismissible;

  /// See [PageRouteBuilder.barrierColor].
  final Color? barrierColor;

  /// See [PageRouteBuilder.barrierLabel].
  final String? barrierLabel;

  /// See [PageRouteBuilder.maintainState].
  final bool maintainState;

  /// See [PageRouteBuilder.fullscreenDialog].
  final bool fullscreenDialog;

  /// See [PageRouteBuilder.allowSnapshotting].
  final bool allowSnapshotting;

  /// The content to be shown in the [PageRoute] created by this page.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _PageBasedResizablePageRoutePageBuilder<T>(
      page: this,
      requestFocus: requestFocus,
      allowSnapshotting: allowSnapshotting,
      fullscreenDialog: fullscreenDialog,
      barrierDismissible: barrierDismissible,
    );
  }
}

class _PageBasedResizablePageRoutePageBuilder<T> extends PageRoute<T>
    with ObservableRouteMixin<T> {
  _PageBasedResizablePageRoutePageBuilder({
    required ResizablePageRoutePageBuilder<T> page,
    super.requestFocus,
    super.allowSnapshotting,
    super.fullscreenDialog,
    super.barrierDismissible,
  }) : super(settings: page);

  ResizablePageRoutePageBuilder<T> get _page =>
      settings as ResizablePageRoutePageBuilder<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  Color? get barrierColor => _page.barrierColor;

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page.reverseTransitionDuration;

  @override
  bool get opaque => _page.opaque;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ResizableNavigatorRouteContentBoundary(
      child: _page.child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _page.transitionsBuilder(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
