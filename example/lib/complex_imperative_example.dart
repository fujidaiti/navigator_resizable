import 'package:example/src/form_page.dart';
import 'package:example/src/multi_page_dialog.dart';
import 'package:example/src/variable_height_page.dart';
import 'package:example/src/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

void main() {
  runApp(MaterialApp(home: const Home(), theme: _theme));
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

void showMultiPageDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return MultiPageDialog(
        navigator: Navigator(
          onGenerateInitialRoutes: (_, __) {
            return [
              MaterialPageRoute(
                builder: (context) => ResizableRouteContent(
                  child: WelcomePage(
                    onNext: () => pushVariableHeightPage(context),
                    onJumpToLast: () {},
                  ),
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
    MaterialPageRoute(
      builder: (context) => ResizableRouteContent(
        child: VariableHeightPage(onNext: () => pushFormPage(context)),
      ),
    ),
  );
}

void pushFormPage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ResizableRouteContent(
        child: FormPage(
          autoFocus: false,
          submitButton: FilledButton(
            onPressed: () => pushFormPageWithAutoFocus(context),
            child: Text('Next'),
          ),
        ),
      ),
    ),
  );
}

void pushFormPageWithAutoFocus(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ResizableRouteContent(
        child: FormPage(
          autoFocus: true,
          submitButton: FilledButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text('Submit'),
          ),
        ),
      ),
    ),
  );
}

final _theme = ThemeData(
  // The default Android page transition supports the predictive back gesture,
  // which makes the navigator size follow the gesture and then jump back when
  // the gesture is committed. This page transition does not support it, so the
  // size animation runs only after the gesture is committed.
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
  ),
);
