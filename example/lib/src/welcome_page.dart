import 'package:example/src/dialog_content_layout.dart';
import 'package:flutter/material.dart';

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
    return DialogPageLayout(
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
