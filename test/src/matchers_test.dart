import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'matchers.dart';

void main() {
  group('isMonotonic', () {
    test('matches an increasing sequence of doubles', () {
      expect([1.0, 2.0, 3.0, 4.0], isMonotonicallyIncreasing);
      expect([0.0, 0.5, 1.5], isMonotonicallyIncreasing);
    });

    test(
      'does not match a non-increasing sequence when expecting increasing',
      () {
        expect([1.0, 2.0, 1.0], isNot(isMonotonicallyIncreasing));
        expect([3.0, 2.0, 1.0], isNot(isMonotonicallyIncreasing));
        expect([1.0], isNot(isMonotonicallyIncreasing)); // Less than 2 elements
      },
    );

    test('matches a decreasing sequence of doubles', () {
      expect([4.0, 3.0, 2.0, 1.0], isMonotonicallyDecreasing);
      expect([1.5, 0.5, -0.5], isMonotonicallyDecreasing);
    });

    test(
      'does not match a non-decreasing sequence when expecting decreasing',
      () {
        expect([1.0, 2.0, 3.0], isNot(isMonotonicallyDecreasing));
        expect([1.0], isNot(isMonotonicallyDecreasing));
      },
    );

    test('does match a sequence with equal consecutive values', () {
      expect([1.0, 1.0, 2.0], isMonotonicallyIncreasing);
      expect([2.0, 1.0, 1.0], isMonotonicallyDecreasing);
    });

    test('does not match an empty list', () {
      expect(<double>[], isNot(isMonotonicallyIncreasing));
    });

    test('handles edge case of a single-element list', () {
      expect([1.0], isNot(isMonotonicallyIncreasing));
    });

    test('does not match sequences with NaN values', () {
      expect([1.0, double.nan, 2.0], isNot(isMonotonicallyIncreasing));
    });

    test('does not match non-iterable objects', () {
      expect('not a list', isNot(isMonotonicallyIncreasing));
      expect(null, isNot(isMonotonicallyIncreasing));
    });
  });

  group('isStrictly', () {
    test('matches a strictly increasing or decreasing sequence', () {
      expect([1.0, 2.0, 3.0], isStrictlyIncreasing);
      expect([3.0, 2.0, 1.0], isStrictlyDecreasing);
    });

    test('does not match a sequence with equal consecutive values', () {
      expect([1.0, 1.0, 2.0], isNot(isStrictlyIncreasing));
      expect([2.0, 1.0, 1.0], isNot(isStrictlyDecreasing));
    });
  });

  group('Sequence of sizes', () {
    test('matches if both widths and heights are monotonic', () {
      expect(const [Size(1, 2), Size(2, 3), Size(3, 4)], isStrictlyIncreasing);
      expect(const [Size(3, 4), Size(2, 3), Size(1, 2)], isStrictlyDecreasing);
    });

    test(
      'does not match if widths and heights move in opposite directions',
      () {
        const sizes = [Size(1, 4), Size(2, 3), Size(3, 2)];
        expect(sizes, isNot(isMonotonicallyIncreasing));
        expect(sizes, isNot(isMonotonicallyDecreasing));
      },
    );
  });
}
