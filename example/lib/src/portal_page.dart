import 'package:example/src/dialog_content_layout.dart';
import 'package:flutter/material.dart';

class PortalPage extends StatelessWidget {
  const PortalPage({
    super.key,
    required this.destinations,
    required this.onGoToDestination,
  });

  final List<String> destinations;
  final void Function(String) onGoToDestination;

  @override
  Widget build(BuildContext context) {
    return DialogPageLayout(
      title: Text('Portal Page'),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final dest in destinations)
              ActionChip(
                label: Text(dest),
                onPressed: () => onGoToDestination(dest),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          // We need to refer to the root navigator to pop the entire dialog.
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
