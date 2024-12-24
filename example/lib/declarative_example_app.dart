import 'package:example/multi_page_dialog.dart';
import 'package:flutter/material.dart';
import 'package:resizable_navigator/resizable_navigator.dart';

/// A declarative version of [showDialog].
///
/// Because the SDK does not provide a [Page] for dialog widgets,
/// we need to create it ourselves.
class MultiPageDialogPage extends Page {
  const MultiPageDialogPage({
    super.key,
    required this.transitionObserver,
    required this.navigator,
  });

  final RouteTransitionObserver transitionObserver;
  final Widget navigator;

  @override
  Route createRoute(BuildContext context) {
    return _PageBasedMultiPageDialogRoute(page: this);
  }
}

class _PageBasedMultiPageDialogRoute extends PageRoute<void> {
  _PageBasedMultiPageDialogRoute({
    required MultiPageDialogPage page,
  }) : super(settings: page);

  MultiPageDialogPage get page => settings as MultiPageDialogPage;

  @override
  Color? get barrierColor => Colors.black45;

  @override
  String? get barrierLabel => null;

  @override
  bool get barrierDismissible => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 150);

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return MultiPageDialog(
      transitionObserver: page.transitionObserver,
      navigator: page.navigator,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
