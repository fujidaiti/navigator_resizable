import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TypeMatcher<Route<dynamic>> isRoute({String? name}) {
  var result = isA<Route<dynamic>>();
  if (name != null) {
    result = result.having(
      (it) => it.settings.name,
      'settings.name',
      name,
    );
  }
  return result;
}

/// Returns a matcher that matches if an object is a sequence of [double] or
/// [Size] values that are monotonically increasing.
///
/// A sequence of [Size]s is monotonic only if both its widths and heights are.
/// The matcher does not match if the sequence has less than two elements.
const Matcher isMonotonicallyIncreasing = _IsMonotonic(
  increasing: true,
  strict: false,
);

/// Returns a matcher that matches if an object is a sequence of [double] or
/// [Size] values that are monotonically decreasing.
///
/// A sequence of [Size]s is monotonic only if both its widths and heights are.
/// The matcher does not match if the sequence has less than two elements.
const Matcher isMonotonicallyDecreasing = _IsMonotonic(
  increasing: false,
  strict: false,
);

/// Same as [isMonotonicallyIncreasing], but does not match if any two
/// consecutive values are equal.
const Matcher isStrictlyIncreasing = _IsMonotonic(
  increasing: true,
  strict: true,
);

/// Same as [isMonotonicallyDecreasing], but does not match if any two
/// consecutive values are equal.
const Matcher isStrictlyDecreasing = _IsMonotonic(
  increasing: false,
  strict: true,
);

class _IsMonotonic extends Matcher {
  const _IsMonotonic({required this.increasing, required this.strict});

  final bool increasing;
  final bool strict;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    // Each value is represented by its components, which must all be
    // monotonic in the same direction.
    final values = switch (item) {
      final Iterable<double> it => [
        for (final v in it) [v],
      ],
      final Iterable<Size> it => [
        for (final s in it) [s.width, s.height],
      ],
      _ => null,
    };
    if (values == null || values.length < 2) {
      return false;
    }

    for (var i = 0; i < values.length; i++) {
      for (var c = 0; c < values[i].length; c++) {
        final current = values[i][c];
        if (current.isNaN) {
          return false;
        }
        if (i == 0) {
          continue;
        }
        final diff = current - values[i - 1][c];
        final isValid = switch ((increasing, strict)) {
          (true, true) => diff > 0,
          (true, false) => diff >= 0,
          (false, true) => diff < 0,
          (false, false) => diff <= 0,
        };
        if (!isValid) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Description describe(Description description) => description.add(
    'A sequence of ${strict ? 'strictly' : 'monotonically'} '
    '${increasing ? 'increasing' : 'decreasing'} numbers or sizes',
  );
}
