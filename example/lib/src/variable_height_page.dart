import 'dart:math';

import 'package:example/src/dialog_content_layout.dart';
import 'package:flutter/material.dart';

class VariableHeightPage extends StatefulWidget {
  const VariableHeightPage({
    super.key,
    required this.onNext,
  });

  final VoidCallback onNext;

  @override
  State<VariableHeightPage> createState() => _VariableHeightPageState();
}

class _VariableHeightPageState extends State<VariableHeightPage> {
  var itemCount = 0;

  @override
  Widget build(BuildContext context) {
    return DialogPageLayout(
      title: const Text('Variable Height Page'),
      description: const Text('This page has a variable height.'),
      children: [
        ConstrainedBox(
          // Limit the height of the scroll view to 280.
          constraints: BoxConstraints.loose(Size.fromHeight(280)),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = itemCount; i > 0; i--)
                  Chip(label: Text('Item #$i')),
              ],
            ),
          ),
        ),
        const Divider(
          height: 24,
        ),
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
            const Spacer(),
            FilledButton(
              onPressed: widget.onNext,
              child: Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}
