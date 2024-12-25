import 'dart:math';

import 'package:flutter/material.dart';
import 'package:resizable_navigator/resizable_navigator.dart';

class MultiPageDialog extends StatelessWidget {
  const MultiPageDialog({
    super.key,
    required this.transitionObserver,
    required this.navigator,
  });

  final RouteTransitionObserver transitionObserver;
  final Widget navigator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(context).top + 24,
        right: 24,
        left: 24,
        bottom: max(
          MediaQuery.viewInsetsOf(context).bottom,
          MediaQuery.viewPaddingOf(context).bottom + 24,
        ),
      ),
      child: Center(
        child: Material(
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: NavigatorResizable(
            transitionObserver: transitionObserver,
            child: navigator,
          ),
        ),
      ),
    );
  }
}
