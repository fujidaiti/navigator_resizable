import 'package:flutter_test/flutter_test.dart';

import 'matchers.dart';

void main() {
  group('isMonotonic matcher', () {
    test('matches an increasing sequence of doubles', () {
      expect([1.0, 2.0, 3.0, 4.0], isMonotonic(increasing: true));
      expect([0.0, 0.5, 1.5], isMonotonic(increasing: true));
    });

    test('does not match a non-increasing sequence when expecting increasing',
        () {
      expect([1.0, 2.0, 1.0], isNot(isMonotonic(increasing: true)));
      expect([3.0, 2.0, 1.0], isNot(isMonotonic(increasing: true)));
      expect(
          [1.0], isNot(isMonotonic(increasing: true))); // Less than 2 elements
    });

    test('matches a decreasing sequence of doubles', () {
      expect([4.0, 3.0, 2.0, 1.0], isMonotonic(increasing: false));
      expect([1.5, 0.5, -0.5], isMonotonic(increasing: false));
    });

    test('does not match a non-decreasing sequence when expecting decreasing',
        () {
      expect([1.0, 2.0, 3.0], isNot(isMonotonic(increasing: false)));
      expect([1.0], isNot(isMonotonic(increasing: false)));
    });

    test('does not match an empty list', () {
      expect(<double>[], isNot(isMonotonic(increasing: true)));
    });

    test('handles edge case of a single-element list', () {
      expect([1.0], isNot(isMonotonic(increasing: true)));
    });

    test('does not match sequences with NaN values', () {
      expect([1.0, double.nan, 2.0], isNot(isMonotonic(increasing: true)));
    });

    test('does not match non-iterable objects', () {
      expect('not a list', isNot(isMonotonic(increasing: true)));
      expect(null, isNot(isMonotonic(increasing: true)));
    });
  });
}
