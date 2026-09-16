// A minimal reproduction of two Flutter framework bugs in Overlay/OverlayPortal.
//
// This file does not use navigator_resizable at all. It only uses widgets from
// the Flutter framework, which shows that the bugs belong to the framework and
// not to this package.
//
// Both bugs happen in `_RenderLayoutSurrogateProxyBox.performLayout`
// (packages/flutter/lib/src/widgets/overlay.dart), which lays out the overlay
// child of an OverlayPortal:
//
//   final BoxConstraints theaterConstraints = theater.constraints;
//   final Size boxSize = theaterConstraints.biggest.isFinite
//       ? theaterConstraints.biggest
//       : theater.size;
//   deferredChild._doLayoutFrom(this, constraints: BoxConstraints.tight(boxSize));
//
// Run this app and tap each button to reproduce. Every case shows a Tooltip,
// because Tooltip is built on OverlayPortal.

import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overlay framework bug repro')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Case A: loose + alwaysSizeToContent'),
            subtitle: const Text(
              "Throws \"'size == theater.size': is not true\".",
            ),
            onTap: () => _push(context, const LooseSizeToContentPage()),
          ),
          ListTile(
            title: const Text('Case B: tight + alwaysSizeToContent'),
            subtitle: const Text('Works. Shown for comparison.'),
            onTap: () => _push(context, const TightSizeToContentPage()),
          ),
          ListTile(
            title: const Text('Case C: unbounded constraint'),
            subtitle: const Text(
              "Throws \"RenderBox.size accessed beyond the scope of resize, "
              'layout, or permitted parent access".',
            ),
            onTap: () => _push(context, const UnboundedOverlayPage()),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

/// The content placed inside every Overlay below.
///
/// It asks for a fixed 300x400 size, and shows a [Tooltip] as soon as it is
/// mounted so that no interaction is needed to reproduce the bugs.
class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  final _tooltipKey = GlobalKey<TooltipState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tooltipKey.currentState?.ensureTooltipVisible();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 400,
      color: Colors.lightBlue.shade100,
      child: Center(
        child: Tooltip(
          key: _tooltipKey,
          message: 'This tooltip is an OverlayPortal',
          child: const Icon(Icons.info_outline, size: 48),
        ),
      ),
    );
  }
}

/// Case A: an Overlay with `alwaysSizeToContent: true` under a loose,
/// finite constraint.
///
/// The theater sizes itself to the content (300x400), but the surrogate box
/// takes the `theaterConstraints.biggest` branch and lays the tooltip out
/// against the full available space instead. `_computeNewLayoutInfo` then
/// fails on `assert(size == theater.size)`, because the framework assumes
/// the theater always fills its constraints.
class LooseSizeToContentPage extends StatelessWidget {
  const LooseSizeToContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case A: loose')),
      // Align passes a loose constraint, so biggest is the full screen size
      // while the theater sizes itself to 300x400.
      body: Align(
        child: Overlay(
          alwaysSizeToContent: true,
          initialEntries: [
            OverlayEntry(
              canSizeOverlay: true,
              builder: (_) => const _Content(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Case B: the same Overlay under a tight constraint. This one works.
///
/// Here `theaterConstraints.biggest` equals the theater's own size, so the
/// assumption in the surrogate box happens to hold. This shows that the
/// trigger for case A is `constraints.biggest != theater.size`.
class TightSizeToContentPage extends StatelessWidget {
  const TightSizeToContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case B: tight')),
      body: Center(
        child: SizedBox(
          width: 300,
          height: 400,
          child: Overlay(
            alwaysSizeToContent: true,
            initialEntries: [
              OverlayEntry(
                canSizeOverlay: true,
                builder: (_) => const _Content(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Case C: a plain Overlay under an unbounded constraint.
///
/// `theaterConstraints.biggest` is infinite, so the surrogate box falls back to
/// reading `theater.size`. The value itself is already final at that point, but
/// the surrogate is neither the theater nor the theater's parent, so the
/// `sizeAccessAllowed` check in `RenderBox.size` rejects the read.
///
/// Note that the check lives inside an `assert`, so this case throws only in
/// debug mode.
class UnboundedOverlayPage extends StatelessWidget {
  const UnboundedOverlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case C: unbounded')),
      // UnconstrainedBox passes an unbounded constraint to the Overlay.
      body: UnconstrainedBox(
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              canSizeOverlay: true,
              builder: (_) => const _Content(),
            ),
          ],
        ),
      ),
    );
  }
}
