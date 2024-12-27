import 'package:flutter/material.dart';
import 'package:resizable_navigator/resizable_navigator.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          // Try changing the alignment for fun!
          alignment: Alignment.center,
          child: ColoredBox(
            color: Colors.purple,
            // STEP1: Wrap the navigator with NavigatorResizable.
            child: NavigatorResizable(
              transitionObserver: transitionObserver,
              child: Navigator(
                observers: [transitionObserver],
                onGenerateInitialRoutes: (_, __) => [
                  // STEP2: Use ResizableMaterialPageRoute instead of MaterialPageRoute.
                  //
                  // That's it!
                  ResizableMaterialPageRoute(
                    builder: (context) => const SmallPage(),
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

final transitionObserver = RouteTransitionObserver();

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
                ResizableMaterialPageRoute(
                  builder: (context) => const MediumPage(),
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
                  ResizableMaterialPageRoute(
                    builder: (context) => const LargePage(),
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
