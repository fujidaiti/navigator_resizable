import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  var currentLocation = '/a/b/c/d';

  void setLocation(String location) {
    setState(() {
      currentLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      onGenerateRoute: (settings) {},
      onGenerateInitialRoutes: (settings) {
        return [
          DiagnosticableMaterialPageRoute(
            identifier: 'Page A',
            builder: (context) {
              return PageA();
            },
          )
        ];
      },
    );
    // const pageA = DiagnosticableMaterialPage(
    //   key: ValueKey('/a'),
    //   identifier: 'Page A',
    //   child: PageA(),
    // );
    // const pageB = DiagnosticableMaterialPage(
    //   key: ValueKey('/b'),
    //   identifier: 'Page B',
    //   child: PageB(),
    // );
    // const pageC = DiagnosticableMaterialPage(
    //   key: ValueKey('/c'),
    //   identifier: 'Page C',
    //   child: PageC(),
    // );
    // const pageD = DiagnosticableMaterialPage(
    //   key: ValueKey('/d'),
    //   identifier: 'Page D',
    //   child: PageD(),
    // );
    // return MaterialApp(
    //   builder: (context, child) {
    //     return Navigator(
    //       onDidRemovePage: (page) {},
    //       pages: switch (currentLocation) {
    //         '/a' => [pageA],
    //         '/a/b' => [pageA, pageB],
    //         '/a/b/c' => [pageA, pageB, pageC],
    //         '/a/b/c/d' => [pageA, pageB, pageC, pageD],
    //         '/c' => [pageC],
    //         _ => throw StateError('Unknown location: $currentLocation'),
    //       },
    //     );
    //   },
    // );
  }
}

class PageA extends StatelessWidget {
  const PageA({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page A'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () {
            // context
            //     .findAncestorStateOfType<_ExampleAppState>()!
            //     .setLocation('/a/b/c/d');

            Navigator.push(
              context,
              DiagnosticableMaterialPageRoute(
                identifier: 'Page B',
                builder: (context) => PageB(),
              ),
            );

            // Navigator.push(
            //   context,
            //   DiagnosticableMaterialPageRoute(
            //     identifier: 'Page C',
            //     builder: (context) => PageC(),
            //   ),
            // );
            // Navigator.push(
            //   context,
            //   DiagnosticableMaterialPageRoute(
            //     identifier: 'Page D',
            //     builder: (context) => PageD(),
            //   ),
            // );
          },
          child: Text('Go to Page B'),
        ),
      ),
    );
  }
}

class PageB extends StatelessWidget {
  const PageB({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page B'),
        leading: IconButton(
          onPressed: () {
            context
                .findAncestorStateOfType<_ExampleAppState>()!
                .setLocation('/a');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () {
            // context
            //     .findAncestorStateOfType<_ExampleAppState>()!
            //     .setLocation('/c');
            Navigator.pushReplacement(
              context,
              DiagnosticableMaterialPageRoute(
                identifier: 'Page C',
                builder: (context) => PageC(),
              ),
            );
          },
          child: Text('Go to Page C'),
        ),
      ),
    );
  }
}

class PageC extends StatelessWidget {
  const PageC({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page C'),
        leading: IconButton(
          onPressed: () {
            context
                .findAncestorStateOfType<_ExampleAppState>()!
                .setLocation('/a');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: Text('Go to PageC'),
        ),
      ),
    );
  }
}

class PageD extends StatelessWidget {
  const PageD({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page D'),
        leading: IconButton(
          onPressed: () {
            // context
            //     .findAncestorStateOfType<_ExampleAppState>()!
            //     .setLocation('/a');

            Navigator.popUntil(context, (r) => r.isFirst);
            // Navigator.pushAndRemoveUntil(
            //   context,
            //   DiagnosticableMaterialPageRoute(
            //     identifier: 'Page A',
            //     builder: (context) => PageA(),
            //   ),
            //   (r) => r.isFirst,
            // );
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.popUntil(context, (r) => r.isFirst);
          },
          child: Text('Go to PageC'),
        ),
      ),
    );
  }
}

class DiagnosticableMaterialPageRoute extends MaterialPageRoute {
  DiagnosticableMaterialPageRoute({
    super.settings,
    required this.identifier,
    required super.builder,
  });

  final String identifier;

  @override
  String get debugLabel =>
      '$identifier(offstage=$offstage, isCurrent=$isCurrent, isActive=$isActive, isFirst=$isFirst, ${animation?.status})';

  @override
  void install() {
    super.install();
    debugPrint('$debugLabel: install');
    navigator!.userGestureInProgressNotifier
        .addListener(_onSwipeBackStatusChanged);
    animation!.addListener(_onAnimationTick);
    animation!.addStatusListener(_onAnimationStatusChanged);
    secondaryAnimation!.addListener(_onSecondaryAnimationTick);
    secondaryAnimation!.addStatusListener(_onSecondaryAnimationStatusChanged);
  }

  void _onAnimationTick() {
    debugPrint(
        '$debugLabel: animation.value = ${animation!.value.toStringAsFixed(3)}');
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    debugPrint('$debugLabel: animation.status = $status');
  }

  void _onSecondaryAnimationTick() {
    debugPrint(
        '$debugLabel: 2ndAnimation.value = ${secondaryAnimation!.value.toStringAsFixed(3)}');
  }

  void _onSecondaryAnimationStatusChanged(AnimationStatus status) {
    debugPrint('$debugLabel: 2ndAnimation.status = $status');
  }

  @override
  void didAdd() {
    super.didAdd();
    debugPrint('$debugLabel: didAdd');
  }

  @override
  bool didPop(result) {
    final ret = super.didPop(result);
    debugPrint('$debugLabel: didPop');
    return ret;
  }

  @override
  void didChangeNext(Route? nextRoute) {
    super.didChangeNext(nextRoute);
    final nextLabel = nextRoute is DiagnosticableMaterialPageRoute
        ? nextRoute.debugLabel
        : '<unknown route>';
    debugPrint('$debugLabel: didChangeNext($nextLabel)');
  }

  @override
  void didChangePrevious(Route? previousRoute) {
    super.didChangePrevious(previousRoute);
    final previousLabel = previousRoute is DiagnosticableMaterialPageRoute
        ? previousRoute.debugLabel
        : '<unknown route>';
    debugPrint('$debugLabel: didChangePrevious($previousLabel)');
  }

  @override
  void didPopNext(Route nextRoute) {
    super.didPopNext(nextRoute);
    final nextLabel = nextRoute is DiagnosticableMaterialPageRoute
        ? nextRoute.debugLabel
        : '<unknown route>';
    debugPrint('$debugLabel: didPopNext($nextLabel)');
  }

  @override
  TickerFuture didPush() {
    final future = super.didPush();
    debugPrint('$debugLabel: didPush');
    return future;
  }

  @override
  void didReplace(Route? oldRoute) {
    super.didReplace(oldRoute);

    final oldLabel = oldRoute is DiagnosticableMaterialPageRoute
        ? oldRoute.debugLabel
        : '<unknown route>';
    debugPrint('$debugLabel: didReplace($oldLabel)');
  }

  @override
  void didComplete(result) {
    super.didComplete(result);
    debugPrint('$debugLabel: didComplete');
  }

  @override
  void dispose() {
    debugPrint('$debugLabel: dispose');
    navigator!.userGestureInProgressNotifier
        .removeListener(_onSwipeBackStatusChanged);
    animation!.removeListener(_onAnimationTick);
    animation!.removeStatusListener(_onAnimationStatusChanged);
    super.dispose();
  }

  void _onSwipeBackStatusChanged() {
    if (navigator!.userGestureInProgress) {
      debugPrint('$debugLabel: User gesture started');
    } else {
      debugPrint('$debugLabel: User gesture stopped');
    }
  }
}

class DiagnosticableMaterialPage extends MaterialPage {
  const DiagnosticableMaterialPage({
    required super.key,
    required this.identifier,
    required super.child,
  });

  final String identifier;

  @override
  Route createRoute(BuildContext context) {
    return _PageBasedMaterialPageRoute(
      page: this,
      identifier: identifier,
    );
  }
}

class _PageBasedMaterialPageRoute<T> extends DiagnosticableMaterialPageRoute {
  _PageBasedMaterialPageRoute({
    required MaterialPage<T> page,
    required super.identifier,
  }) : super(settings: page, builder: (context) => page.child) {
    assert(opaque);
  }

  MaterialPage<T> get _page => settings as MaterialPage<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;
}
