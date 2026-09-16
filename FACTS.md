# NavigatorResizable and OverlayPortal: triage findings

Status: investigation notes. No fix has been applied to `lib/`.

- Package: `navigator_resizable` `3.2.0-wip`
- Regressing commit: `df6c21240ceb491e45511d36e283f620f00c3989` (#54)
- Last good commit: `77995a3` (`3.1.0`)
- Flutter: 3.47.4 stable, revision `9584c6713b`
- Tracking issue: https://github.com/fujidaiti/navigator_resizable/issues/58
- Related: https://github.com/fujidaiti/smooth_sheets/issues/167

All line numbers below refer to Flutter 3.47.4.

---

## 1. The defect

Showing an `OverlayPortal` from a route hosted by a `Navigator` under a
`NavigatorResizable` throws in debug mode:

```
RenderBox.size accessed beyond the scope of resize, layout, or permitted parent access.
'package:flutter/src/rendering/box.dart': Failed assertion: line 2268 pos 11: 'sizeAccessAllowed'

#2  RenderBox.size.<anonymous closure> (package:flutter/src/rendering/box.dart:2268:11)
#3  RenderBox.size (package:flutter/src/rendering/box.dart:2302:6)
#4  _RenderLayoutSurrogateProxyBox.performLayout (package:flutter/src/widgets/overlay.dart:2795:21)
#5  RenderObject._layoutWithoutResize (package:flutter/src/rendering/object.dart:2771:7)
#6  PipelineOwner.flushLayout (package:flutter/src/rendering/object.dart:1174:18)
```

Cascading assertions follow at `object.dart:6018` and `object.dart:5724`
(semantics parent-data checks).

### Scope (measured on both commits)

| Scenario | 3.1.0 (`77995a3`) | 3.2.0-wip (`df6c212`) |
|---|---|---|
| Inserting a plain `OverlayEntry` from a route | pass | pass |
| Showing an `OverlayPortal` from a route | pass | **fail** |
| Showing a `Tooltip` from a route | pass | **fail** |
| Opening a `PopupMenuButton` from a route | pass | pass |
| Opening a `DropdownButton` from a route | pass | pass |
| `SelectionArea` (no toolbar shown) | pass | pass |

Plain `OverlayEntry` insertions are unaffected because `_RenderTheater` lays
non-size-determining children out with a tight constraint derived from its own
already-computed size. Route-based popups (`PopupMenuButton`, `DropdownButton`)
are unaffected because they push a route instead of inserting an overlay child.

Affected framework widgets are the ones built on `OverlayPortal`: `Tooltip`,
`RawAutocomplete`, `DropdownMenu` / `MenuAnchor`, and text selection handles and
toolbar.

Regression tests covering the first three rows are committed in
`test/navigator_resizable_test.dart` (group `Overlay entry compatibility test`,
commit `2585668`).

---

## 2. Root cause

### 2.1 What `df6c212` changed

`_RenderNavigatorResizable.performLayout` now lays the child `Navigator` out with
an unbounded constraint so that the navigator shrink-wraps to the route content:

```dart
child!.layout(
  const BoxConstraints(
    maxWidth: double.infinity,
    maxHeight: double.infinity,
  ),
  parentUsesSize: true,
);
```

That constraint reaches the navigator's `Overlay`, so `_RenderTheater` receives
`maxWidth` and `maxHeight` of `double.infinity`.

### 2.2 The framework code that breaks

`_RenderLayoutSurrogateProxyBox.performLayout`, `overlay.dart:2791`:

```dart
if (!theater._layingOutSizeDeterminingChild) {
  final BoxConstraints theaterConstraints = theater.constraints;
  final Size boxSize = theaterConstraints.biggest.isFinite
      ? theaterConstraints.biggest
      : theater.size;                 // <- assertion fires here
  deferredChild._doLayoutFrom(this, constraints: BoxConstraints.tight(boxSize));
}
```

With an unbounded theater, `theaterConstraints.biggest.isFinite` is `false`, so
the fallback reads `theater.size`.

### 2.3 The read is legal by value, illegal by access rule

`theater._size` is already assigned at that point. `_RenderTheater.performLayout`
(`overlay.dart:1466`) assigns `size` before laying out any non-size-determining
child, and the `_layingOutSizeDeterminingChild` guard covers the one window where
it is not yet assigned:

```dart
if (!alwaysSizeToContent && constraints.biggest.isFinite) {
  size = constraints.biggest;                    // assigned first
} else {
  sizeDeterminingChild = _findSizeDeterminingChild();
  _layingOutSizeDeterminingChild = true;
  layoutChild(sizeDeterminingChild, constraints);
  _layingOutSizeDeterminingChild = false;
  size = sizeDeterminingChild.size;              // assigned here
}
```

The value is also current rather than stale: `PipelineOwner.flushLayout`
processes dirty nodes in ascending depth order, so the theater, being an
ancestor, is laid out before the surrogate.

What fails is the access rule in `RenderBox.size` (`box.dart:2261`):

```dart
final bool sizeAccessAllowed =
    !doingRegularLayout ||
    debugDoingThisResize ||
    debugDoingThisLayout ||
    _debugDoingBaseline ||
    RenderObject.debugActiveLayout == parent && size._canBeUsedByParent;
```

Only the render object itself or its own parent may read the size during layout.
In the failing stack the surrogate is its own relayout boundary and is laid out
directly from `PipelineOwner.flushLayout`, while the theater is not in layout at
all. `debugActiveLayout` is therefore the surrogate, which is neither the theater
nor the theater's parent, so every clause is false.

### 2.4 Consequence for release builds

`sizeAccessAllowed` sits inside an `assert`, so release and profile builds skip
the check, read the correct size and lay the deferred child out against the
theater's shrink-wrapped size. The unbounded path therefore appears to behave
correctly outside debug mode.

Not verified by running a release build. This is reasoning from the source only.

---

## 3. Why the obvious fixes do not work

The navigator's unbounded constraint serves two purposes, and only one of them is
about sizing.

1. The `Overlay` shrink-wraps, so `NavigatorResizable` can read the content size
   in the same layout pass.
2. An unbounded `_RenderTheater` lays its size-determining child out with the
   incoming, non-tight constraint. `RenderObject.layout` makes a child its own
   relayout boundary when `constraints.isTight`, so a non-tight constraint is
   what keeps content size changes propagating up to `_RenderNavigatorResizable`
   within the same frame. This is the one-frame delay that `#54` removed.

A plain `_RenderTheater` that is given a bounded constraint takes
`size = constraints.biggest` and then lays **every** child out with
`BoxConstraints.tight(size)`, which cuts that propagation.

### Measured attempts

| Attempt | Overlay tests | Same-frame size update |
|---|---|---|
| Second navigator layout pass with `BoxConstraints.tight(shrinkWrappedSize)` | pass | fail (6 tests) |
| Second navigator layout pass with `BoxConstraints.loose(shrinkWrappedSize)` | pass | fail (1 test) |
| Loose second pass plus `_RenderRouteContentBoundary` marking the resizable dirty | — | assertion error |

The third attempt fails with:

```
A _RenderNavigatorResizable was mutated in _RenderRouteContentBoundary.performLayout.
The RenderObject was mutated when none of its ancestors is actively performing layout.
```

Flutter forbids marking an ancestor as needing layout from inside the layout
phase, so propagation cannot be restored once the theater is bounded.

---

## 4. Working approach: a per-route `Overlay`

Idea taken from the workaround in smooth_sheets#167. Insert an `Overlay` inside
`ResizableNavigatorRouteContentBoundary`, between the boundary render object and
the route content:

```
_RenderRouteContentBoundary          <- measures the content size
  └─ Overlay(alwaysSizeToContent: true)
       └─ OverlayEntry(canSizeOverlay: true, opaque: true, maintainState: true)
            └─ route content
```

Two properties make this fit the current architecture:

- `alwaysSizeToContent: true` keeps the shrink-wrapping, and the theater lays the
  size-determining child out with the incoming constraint via `layoutChild`
  (`overlay.dart:1120`), which passes `parentUsesSize: true`. As long as that
  constraint is not tight, same-frame propagation survives.
- The theater now receives a finite constraint, so
  `_RenderLayoutSurrogateProxyBox` takes the `theaterConstraints.biggest` branch
  and never reads `theater.size`. The original crash disappears.

### A second assertion appears, and why two layout passes are required

Passing `bypassedConstraints` straight into the inner `Overlay` fixes plain
`OverlayPortal` but still fails for `Tooltip`:

```
'package:flutter/src/widgets/overlay.dart': Failed assertion: line 2895 pos 12:
'size == theater.size': is not true.
```

Concrete case: an 800x600 screen, route content that wants to be 300x400, so
`bypassedConstraints` is `BoxConstraints(0<=w<=800, 0<=h<=600)`.

| Value | Result |
|---|---|
| `theater.constraints.biggest` | `Size(800, 600)` |
| `theater.size` (because `alwaysSizeToContent`) | `Size(300, 400)` |

The surrogate lays the deferred child out with `tight(800x600)`, then
`_computeNewLayoutInfo` asserts `size == theater.size` and fails. The framework
assumes the theater fills its constraints, which is exactly what
`alwaysSizeToContent` breaks. This path runs only for widgets that use
`OverlayPortal.overlayChildLayoutBuilder`, which is why plain `OverlayPortal`
passes with a single pass and `Tooltip` does not.

Satisfying `constraints.biggest == theater.size` requires a constraint whose
maximum is already the content size, and the content size is the output of
laying the content out. One pass cannot produce it, so the boundary measures
first and re-lays out second:

```dart
child.layout(bypassedConstraints, parentUsesSize: true);
child.layout(
  BoxConstraints.loose(Size.copy(child.size)),
  parentUsesSize: true,
);
```

`BoxConstraints.tight(contentSize)` would also satisfy the assertion, but it
would make the size-determining child its own relayout boundary and reintroduce
the one-frame delay. `loose` gives a finite `biggest` equal to the theater's size
while staying non-tight, satisfying both requirements.

### Verified results

| Check | Before | After |
|---|---|---|
| Existing 80 tests | pass | pass |
| Same-frame content size update | pass | pass |
| Plain `OverlayEntry` from a route | pass | pass |
| `OverlayPortal` from a route | crash | pass |
| `Tooltip` from a route | crash | pass |
| `DropdownMenu` from a route | crash | pass |
| Text selection toolbar | pass | pass |

Full suite: 83 of 83 passing with the prototype applied.

The tooltip rectangle lies entirely inside the `NavigatorResizable` bounds,
asserted in a scratch test, because the per-route overlay is exactly the size of
the route content. This also addresses smooth_sheets#167.

### Costs and behavior changes

1. The content subtree is laid out twice per pass, since the second pass uses
   different constraints. The second call can be skipped when
   `bypassedConstraints.biggest == child.size`, which covers routes that fill the
   available space.
2. `Overlay.of(context)` inside a route returns the per-route overlay rather than
   the navigator's. Entries inserted by user code become route-sized instead of
   navigator-sized. This is arguably the desired behavior but is a visible change
   to the public `ResizableNavigatorRouteContentBoundary` and needs documenting.
3. One extra `Overlay` and `OverlayEntry` per route.
4. Both framework assertions remain framework bugs. This is a workaround, not a
   fix.

### Prototype

The full prototype is saved outside the repository at:

```
/private/tmp/claude-501/-Users-fujidaiti-Dev-navigator-resizable-overlay-compat/afa0d838-d6b5-4ead-ae6c-7dca2b821b17/scratchpad/navigator_resizable.patched.dart
```

It changes `ResizableNavigatorRouteContentBoundary.build` to wrap `child` in a
new private `_RouteContentOverlay` stateful widget, and adds the second
`child.layout` call in `_RenderRouteContentBoundary.performLayout`.

---

## 5. Recommended actions

1. Report both framework bugs upstream. The first is the parent-access violation
   in `_RenderLayoutSurrogateProxyBox.performLayout`, fixable by caching the
   theater's size in a plain field written at the end of
   `_RenderTheater.performLayout`. The second is the
   `size == theater.size` assumption in `_computeNewLayoutInfo`, which does not
   hold when `alwaysSizeToContent` is set.
2. Adopt the per-route `Overlay` workaround in Section 4, with the second layout
   pass skipped where possible, and document the `Overlay.of` behavior change.
3. Correct the architecture comment added by `df6c212`, which states that
   shrink-wrapping "also allows it to correctly render `OverlayEntry`s such as
   popup menus". Plain `OverlayEntry` insertions do work, but `OverlayPortal`
   does not, so the sentence should be narrowed.
