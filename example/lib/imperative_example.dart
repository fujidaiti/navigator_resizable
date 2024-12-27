import 'package:example/src/form_page.dart';
import 'package:example/src/multi_page_dialog.dart';
import 'package:example/src/variable_height_page.dart';
import 'package:example/src/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:resizable_navigator/resizable_navigator.dart';

void main() {
  runApp(const MaterialApp(home: Home()));
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showMultiPageDialog(context),
          child: const Text('Open Dialog'),
        ),
      ),
    );
  }
}

final transitionObserver = RouteTransitionObserver();

void showMultiPageDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return MultiPageDialog(
        transitionObserver: transitionObserver,
        navigator: Navigator(
          observers: [transitionObserver],
          onGenerateInitialRoutes: (_, __) {
            return [
              ResizableMaterialPageRoute(
                builder: (context) => WelcomePage(
                  onNext: () => pushVariableHeightPage(context),
                  onJumpToLast: () {},
                ),
              ),
            ];
          },
        ),
      );
    },
  );
}

void pushVariableHeightPage(BuildContext context) {
  Navigator.push(
    context,
    ResizableMaterialPageRoute(
      builder: (context) => VariableHeightPage(
        onNext: () => pushFormPage(context),
      ),
    ),
  );
}

void pushFormPage(BuildContext context) {
  Navigator.push(
    context,
    ResizableMaterialPageRoute(
      builder: (context) => FormPage(
        autoFocus: false,
        submitButton: FilledButton(
          onPressed: () => pushFormPageWithAutoFocus(context),
          child: Text('Next'),
        ),
      ),
    ),
  );
}

void pushFormPageWithAutoFocus(BuildContext context) {
  Navigator.push(
    context,
    ResizableMaterialPageRoute(
      builder: (_) => FormPage(
        autoFocus: true,
        submitButton: FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text('Submit'),
        ),
      ),
    ),
  );
}
