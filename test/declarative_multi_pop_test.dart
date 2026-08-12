import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigator_resizable/src/navigator_resizable.dart';
import 'package:navigator_resizable/src/resizable_navigator_routes.dart';

/// Regression tests for the assertion errors that occur when the page stack is
/// changed faster than the route transitions can settle.
///
/// With the Pages API a single `setState` can remove several routes at once,
/// and it can do so while a push transition is still running. In both cases
/// `Route.didChangeNext(null)` is reported for a route that is neither the new
/// top-most route, nor has a next route whose transition is running in reverse.
void main() {
  const pageA = ResizableMaterialPage(
    key: ValueKey('a'),
    child: SizedBox(width: 280, height: 160),
  );
  const pageB = ResizableMaterialPage(
    key: ValueKey('b'),
    child: SizedBox(width: 320, height: 220),
  );
  const pageC = ResizableMaterialPage(
    key: ValueKey('c'),
    child: SizedBox(width: 360, height: 280),
  );
  const pageD = ResizableMaterialPage(
    key: ValueKey('d'),
    child: SizedBox(width: 300, height: 200),
  );

  Widget buildApp(List<Page<dynamic>> pages) {
    return MaterialApp(
      home: Center(
        child: NavigatorResizable(
          child: Navigator(pages: pages, onDidRemovePage: (_) {}),
        ),
      ),
    );
  }

  /// Walks through [stacks], leaving [settleDuration] between each change so
  /// that the transitions are still running when the next change arrives.
  Future<void> walk(
    WidgetTester tester,
    List<List<Page<dynamic>>> stacks, {
    Duration settleDuration = const Duration(milliseconds: 40),
  }) async {
    for (final stack in stacks) {
      await tester.pumpWidget(buildApp(stack));
      await tester.pump(settleDuration);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('Popping two routes in the middle of a push transition', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp([pageA, pageB]));
    await tester.pumpAndSettle();

    await walk(tester, [
      [pageA, pageB, pageC],
      [pageA],
    ]);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Reverting a push in the middle of its transition', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp([pageA, pageB]));
    await tester.pumpAndSettle();

    await walk(tester, [
      [pageA, pageB, pageC],
      [pageA, pageB],
    ]);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Popping routes one after another without settling', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp([pageA, pageB, pageC]));
    await tester.pumpAndSettle();

    await walk(tester, [
      [pageA, pageB],
      [pageA],
    ]);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Replacing the whole stack in the middle of a transition', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp([pageA]));
    await tester.pumpAndSettle();

    await walk(tester, [
      [pageA, pageB, pageC],
      [pageD],
      [pageA, pageB],
      [pageA],
    ]);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Route stack changes still resize the navigator', (tester) async {
    await tester.pumpWidget(buildApp([pageA]));
    await tester.pumpAndSettle();
    final box = tester.renderObject<RenderBox>(
      find.byType(NavigatorResizable),
    );
    expect(box.size, const Size(280, 160));

    await walk(tester, [
      [pageA, pageB, pageC],
      [pageA],
    ]);
    expect(
      box.size,
      const Size(280, 160),
      reason: 'Back at page A, the navigator must be sized to A again.',
    );

    await walk(tester, [
      [pageD],
    ]);
    expect(box.size, const Size(300, 200));
  });
}
