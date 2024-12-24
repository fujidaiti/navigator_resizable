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
      padding: EdgeInsets.all(24),
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

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.onNext,
    required this.onJumpToLast,
  });

  final VoidCallback onNext;
  final VoidCallback onJumpToLast;

  @override
  Widget build(BuildContext context) {
    return _DialogPageLayout(
      title: const Text('Multi-page Dialog Example'),
      description: const Text('This is a multi-page dialog example.'),
      children: [
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
          ),
          child: const Text('Next'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onJumpToLast,
          child: const Text('Jump to the last page'),
        ),
      ],
    );
  }
}

class VariableHeightPage extends StatelessWidget {
  const VariableHeightPage({super.key});

  @override
  Widget build(BuildContext context) {
    var itemCount = 0;
    return StatefulBuilder(
      builder: (context, setState) {
        return _DialogPageLayout(
          title: const Text('Variable Height Page'),
          description: const Text('This page has a variable height.'),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() => itemCount++),
                  icon: Icon(Icons.add),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => itemCount = max(itemCount - 1, 0)),
                  icon: Icon(Icons.remove),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < itemCount; i++)
                  Chip(label: Text('Item #$i')),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DialogPageLayout extends StatelessWidget {
  const _DialogPageLayout({
    required this.title,
    this.description,
    required this.children,
  });

  final Widget title;
  final Widget? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: CloseButton(
                onPressed: () {
                  // We need to refer to the root navigator to pop the entire dialog.
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  DefaultTextStyle(
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium!,
                    child: title,
                  ),
                  if (description case final description?) ...[
                    const SizedBox(height: 16),
                    DefaultTextStyle(
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!,
                      child: description,
                    ),
                  ],
                  const SizedBox(height: 48),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
