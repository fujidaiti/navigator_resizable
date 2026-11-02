import 'package:flutter/material.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _theme,
      home: Scaffold(
        body: Align(
          // Try changing the alignment for fun!
          alignment: Alignment.center,
          child: Material(
            elevation: 4,
            // STEP1: Wrap the navigator with NavigatorResizable.
            child: NavigatorResizable(
              child: Navigator(
                onGenerateInitialRoutes: (_, __) => [
                  // STEP2: Wrap the content of every route in a
                  // ResizableRouteContent.
                  //
                  // That's it!
                  MaterialPageRoute(
                    builder: (context) =>
                        ResizableRouteContent(child: const SmallPage()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SmallPage extends StatelessWidget {
  const SmallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue,
      child: SizedBox.square(
        dimension: 200,
        child: Center(
          child: FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ResizableRouteContent(child: const MediumPage()),
                ),
              );
            },
            child: Text('Push'),
          ),
        ),
      ),
    );
  }
}

class MediumPage extends StatelessWidget {
  const MediumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.green,
      child: SizedBox.square(
        dimension: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ResizableRouteContent(child: const LargePage()),
                  ),
                );
              },
              child: Text('Push'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class LargePage extends StatelessWidget {
  const LargePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.green,
      child: SizedBox.expand(
        child: Center(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Back'),
          ),
        ),
      ),
    );
  }
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
