import 'package:example/src/form_page.dart';
import 'package:example/src/multi_page_dialog.dart';
import 'package:example/src/portal_page.dart';
import 'package:example/src/variable_height_page.dart';
import 'package:example/src/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

void main() {
  runApp(MaterialApp.router(routerConfig: _router));
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Home(),
      routes: [
        ShellRoute(
          pageBuilder: (context, state, child) => MultiPageDialogPage(
            key: state.pageKey,
            navigator: child,
          ),
          routes: [
            GoRoute(
              path: 'a',
              pageBuilder: (context, state) => ResizableMaterialPage(
                key: state.pageKey,
                child: WelcomePage(
                  onNext: () => context.go('/a/b'),
                  onJumpToLast: () => context.go('/x'),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'b',
                  pageBuilder: (context, state) => ResizableMaterialPage(
                    key: state.pageKey,
                    child: VariableHeightPage(
                      onNext: () => context.go('/a/b/c'),
                    ),
                  ),
                  routes: [
                    GoRoute(
                      path: 'c',
                      pageBuilder: (context, state) => ResizableMaterialPage(
                        key: state.pageKey,
                        child: FormPage(
                          autoFocus: false,
                          submitButton: FilledButton(
                            onPressed: () => context.go('/a/b/c/d'),
                            child: Text('Next'),
                          ),
                        ),
                      ),
                      routes: [
                        GoRoute(
                          path: 'd',
                          pageBuilder: (context, state) =>
                              ResizableMaterialPage(
                            key: state.pageKey,
                            child: FormPage(
                              autoFocus: true,
                              submitButton: FilledButton(
                                onPressed: () => context.go('/a/b/c/d/e'),
                                child: Text('Next'),
                              ),
                            ),
                          ),
                          routes: [
                            GoRoute(
                              path: 'e',
                              pageBuilder: (context, state) =>
                                  ResizableMaterialPage(
                                key: state.pageKey,
                                child: PortalPage(
                                  destinations: [
                                    '/a/b/c/d',
                                    '/a/b/c',
                                    '/a/b',
                                    '/a',
                                  ],
                                  onGoToDestination: (destination) =>
                                      context.go(destination),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: 'x',
              pageBuilder: (context, state) => ResizableMaterialPage(
                key: state.pageKey,
                child: PortalPage(
                  destinations: [
                    '/a/b/c/d',
                    '/a/b/c',
                    '/a/b',
                    '/a',
                  ],
                  onGoToDestination: (destination) => context.go(destination),
                ),
              ),
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
          onPressed: () => context.go('/A'),
          child: const Text('Open Dialog'),
        ),
      ),
    );
  }
}

/// A declarative version of [showDialog].
///
/// Because the SDK does not provide [Page] for dialog widgets,
/// we need to define one ourselves.
class MultiPageDialogPage extends Page {
  const MultiPageDialogPage({
    super.key,
    required this.navigator,
  });

  final Widget navigator;

  @override
  Route createRoute(BuildContext context) {
    return PageBasedMultiPageDialogRoute(page: this);
  }
}

class PageBasedMultiPageDialogRoute extends PageRoute<void> {
  PageBasedMultiPageDialogRoute({
    required MultiPageDialogPage page,
  }) : super(settings: page);

  MultiPageDialogPage get page => settings as MultiPageDialogPage;

  @override
  Color? get barrierColor => Colors.black45;

  @override
  String? get barrierLabel => null;

  @override
  bool get barrierDismissible => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 150);

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return MultiPageDialog(
      navigator: page.navigator,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
