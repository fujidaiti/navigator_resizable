import 'package:flutter/material.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

class DialogPageLayout extends StatelessWidget {
  const DialogPageLayout({
    super.key,
    required this.title,
    this.description,
    required this.children,
  });

  final Widget title;
  final Widget? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // The content of every page in the dialog is wrapped in this layout,
    // so declaring the boundary here saves doing it in each page.
    return ResizableNavigatorRouteContentBoundary(
      child: Material(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: SingleChildScrollView(
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
        ),
      ),
    );
  }
}
