import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resizable_navigator/resizable_navigator.dart';

void main() {
  runApp(MaterialApp.router(routerConfig: _router));
}

final transitionObserver = RouteTransitionObserver();

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Home(),
      routes: [
        ShellRoute(
          observers: [transitionObserver],
          builder: (context, state, nestedNavigator) => ResizableDialog(
            transitionObserver: transitionObserver,
            child: nestedNavigator,
          ),
          routes: [
            GoRoute(
              path: 'a',
              pageBuilder: (context, state) =>
                  ResizableMaterialPage(child: const DialogPageA()),
              routes: [
                GoRoute(
                  path: 'b',
                  pageBuilder: (context, state) =>
                      ResizableMaterialPage(child: const DialogPageB()),
                  routes: [
                    GoRoute(
                      path: 'c',
                      pageBuilder: (context, state) =>
                          ResizableMaterialPage(child: const DialogPageC()),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/a'),
          child: const Text('Open Dialog'),
        ),
      ),
    );
  }
}

class ResizableDialog extends StatelessWidget {
  const ResizableDialog({
    super.key,
    required this.transitionObserver,
    required this.child,
  });

  final RouteTransitionObserver transitionObserver;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: EdgeInsets.all(56),
        child: Center(
          child: ColoredBox(
            color: Colors.white,
            child: NavigatorResizable(
              transitionObserver: transitionObserver,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class DialogPageA extends StatelessWidget {
  const DialogPageA({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      color: Colors.red,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => context.go('/a/b'),
            child: const Text('Go to B'),
          ),
          TextButton(
            onPressed: () => context.go('/a/b/c'),
            child: const Text('Go to C'),
          ),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class DialogPageB extends StatelessWidget {
  const DialogPageB({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.blue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => context.go('/a/b/c'),
            child: const Text('Go to C'),
          ),
          TextButton(
            onPressed: () => context.go('/a'),
            child: const Text('Back to A'),
          ),
        ],
      ),
    );
  }
}

class DialogPageC extends StatelessWidget {
  const DialogPageC({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.green,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => context.go('/a/b'),
            child: const Text('Back to B'),
          ),
          TextButton(
            onPressed: () => context.go('/a'),
            child: const Text('Back to A'),
          ),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
