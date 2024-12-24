import 'package:example/declarative_example_app.dart';
import 'package:example/multi_page_dialog.dart';
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
          pageBuilder: (context, state, child) => MultiPageDialogPage(
            key: state.pageKey,
            transitionObserver: transitionObserver,
            navigator: child,
          ),
          routes: [
            GoRoute(
              path: 'a',
              pageBuilder: (context, state) => ResizableMaterialPage(
                child: WelcomePage(
                  onNext: () => context.go('/a/b'),
                  onJumpToLast: () {},
                ),
              ),
              routes: [
                GoRoute(
                  path: 'b',
                  pageBuilder: (context, state) => ResizableMaterialPage(
                    child: VariableHeightPage(),
                  ),
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
