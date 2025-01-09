import 'package:flutter/material.dart';

import 'navigator_event_observer.dart';
import 'navigator_resizable.dart';

@optionalTypeArgs
class ResizableMaterialPageRoute<T> extends MaterialPageRoute<T>
    with ObservableRouteMixin<T>, MaterialRouteTransitionMixin<T> {
  ResizableMaterialPageRoute({
    required super.builder,
    super.settings,
    super.requestFocus,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
  });

  @override
  Widget buildContent(BuildContext context) {
    return ResizableNavigatorRouteContentBoundary(
      child: builder(context),
    );
  }
}

@optionalTypeArgs
class ResizableMaterialPage<T> extends MaterialPage<T> {
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

class _PageBasedResizableMaterialPageRoute<T> extends PageRoute<T>
    with ObservableRouteMixin<T>, MaterialRouteTransitionMixin<T> {
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
  Widget buildContent(BuildContext context) {
    return ResizableNavigatorRouteContentBoundary(
      child: page.child,
    );
  }
}
