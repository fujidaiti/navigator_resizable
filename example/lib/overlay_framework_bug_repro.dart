// A minimal reproduction of a Flutter framework bug in Overlay/OverlayPortal.
//
// This file does not use navigator_resizable at all. It only uses widgets from
// the Flutter framework, which shows that the bug belongs to the framework and
// not to this package.
//
// The bug happens in `_RenderLayoutSurrogateProxyBox.performLayout`
// (packages/flutter/lib/src/widgets/overlay.dart), which lays out the overlay
// child of an OverlayPortal:
//
//   final BoxConstraints theaterConstraints = theater.constraints;
//   final Size boxSize = theaterConstraints.biggest.isFinite
//       ? theaterConstraints.biggest
//       : theater.size;
//
// When the Overlay gets an unbounded constraint, `biggest` is infinite, so the
// code falls back to reading `theater.size`. That value is already final at
// that point, but the surrogate is neither the theater nor the theater's
// parent, so the `sizeAccessAllowed` check in `RenderBox.size` rejects the
// read and throws:
//
//   RenderBox.size accessed beyond the scope of resize, layout, or permitted
//   parent access.
//
// The check lives inside an `assert`, so this throws only in debug mode.
//
// Run this app and open the dropdown menu to reproduce. The DropdownMenu is
// what triggers the bug, because it shows its menu with an OverlayPortal.

import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
      ),
    );
  }
}

/// The content placed inside the Overlay.
///
/// It asks for a fixed 300x400 size, and shows a [DropdownMenu] that opens an
/// OverlayPortal when tapped.
class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 400,
      color: Colors.lightBlue.shade100,
      child: Center(
        child: DropdownMenu<int>(
          label: const Text('Tap to reproduce'),
          dropdownMenuEntries: [
            for (var i = 1; i <= 3; i++)
              DropdownMenuEntry(value: i, label: 'Item $i'),
          ],
        ),
      ),
    );
  }
}
