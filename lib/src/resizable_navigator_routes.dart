import 'package:flutter/material.dart';

import 'navigator_resizable.dart';

mixin ResizableNavigatorRouteMixin<T> on ModalRoute<T> {
  NavigatorResizableState? _navigatorResizable;

  @override
  void install() {
    super.install();
    _navigatorResizable = NavigatorResizableState.of(navigator!.context)
      ..didAddRoute(this);
  }

  @override
  void changedExternalState() {
    super.changedExternalState();
    final newNavigatorResizable =
        NavigatorResizableState.of(navigator!.context);
    if (newNavigatorResizable != _navigatorResizable) {
      _navigatorResizable?.didRemoveRoute(this);
      _navigatorResizable = newNavigatorResizable..didAddRoute(this);
    }
  }

  @override
  void dispose() {
    _navigatorResizable?.didRemoveRoute(this);
    _navigatorResizable = null;
    super.dispose();
  }
}

class ResizableMaterialPageRoute<T> extends MaterialPageRoute<T> {
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
    with ResizableNavigatorRouteMixin<T>, MaterialRouteTransitionMixin<T> {
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
