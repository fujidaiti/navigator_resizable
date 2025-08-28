import 'package:flutter/material.dart';
import 'package:navigator_resizable/navigator_resizable.dart';

void main() {
  runApp(const MaterialApp(home: ExampleHome()));
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  // IMPORTANT: Use ResizableMaterialPage instead of MaterialPage.
  late final ResizableMaterialPage _pageA = ResizableMaterialPage(
    key: const ValueKey('a'),
    child: const _ExampleRouteContent(
      title: 'Page A',
      size: Size(280, 160),
      color: Colors.blue,
    ),
  );

  late final ResizableMaterialPage _pageB = ResizableMaterialPage(
    key: const ValueKey('b'),
    child: const _ExampleRouteContent(
      title: 'Page B',
      size: Size(320, 220),
      color: Colors.green,
    ),
  );

  late final ResizableMaterialPage _pageC = ResizableMaterialPage(
    key: const ValueKey('c'),
    child: const _ExampleRouteContent(
      title: 'Page C',
      size: Size(360, 280),
      color: Colors.red,
    ),
  );

  late final ResizableMaterialPage _pageD = ResizableMaterialPage(
    key: const ValueKey('d'),
    child: const _ExampleRouteContent(
      title: 'Page D',
      size: Size(300, 200),
      color: Colors.yellow,
    ),
  );

  late List<Page> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [_pageA];
  }

  void _go(String location) {
    setState(() {
      _pages = switch (location) {
        '/a' => [_pageA],
        '/a/b' => [_pageA, _pageB],
        '/a/b/c' => [_pageA, _pageB, _pageC],
        '/d' => [_pageD],
        _ => throw StateError('Unknown location: $location'),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Material(
                    elevation: 2,
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(8),
                    // IMPORTANT: Wrap the Navigator in a NavigatorResizable.
                    child: NavigatorResizable(
                      child: Navigator(
                        pages: _pages,
                        onDidRemovePage: (removedPage) {
                          _pages.remove(removedPage);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => _go('/a'),
                      child: const Text('Go to /a'),
                    ),
                    FilledButton(
                      onPressed: () => _go('/a/b'),
                      child: const Text('Go to /a/b'),
                    ),
                    FilledButton(
                      onPressed: () => _go('/a/b/c'),
                      child: const Text('Go to /a/b/c'),
                    ),
                    FilledButton(
                      onPressed: () => _go('/d'),
                      child: const Text('Go to /d'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleRouteContent extends StatelessWidget {
  const _ExampleRouteContent({
    required this.title,
    required this.size,
    required this.color,
  });

  final String title;
  final Size size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displayMedium,
      ),
    );
  }
}
