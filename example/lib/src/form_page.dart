import 'package:example/src/dialog_content_layout.dart';
import 'package:flutter/material.dart';

class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.autoFocus,
    required this.onNext,
  });

  final bool autoFocus;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final autoFocus =
        this.autoFocus && ModalRoute.of(context)?.isCurrent == true;
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: DialogPageLayout(
        title: Text('Form Page'),
        description: Text(
          'The dialog can shrink to avoid '
          'being obscured by the on-screen keyboard.',
        ),
        children: [
          TextField(
            autofocus: autoFocus,
            maxLines: null,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Enter your username',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back'),
              ),
              FilledButton(
                onPressed: onNext,
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
