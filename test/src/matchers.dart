import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resizable_navigator/src/route_transition_status.dart';

TypeMatcher<UserGestureTransition> isUserGestureTransition({
  TypeMatcher<dynamic>? currentRoute,
  TypeMatcher<dynamic>? previousRoute,
}) {
  var result = isA<UserGestureTransition>();
  if (currentRoute != null) {
    result = result.having(
      (it) => it.currentRoute,
      'currentRoute',
      currentRoute,
    );
  }
  if (previousRoute != null) {
    result = result.having(
      (it) => it.previousRoute,
      'previousRoute',
      previousRoute,
    );
  }
  return result;
}

TypeMatcher<BackwardTransition> isBackwardTransition({
  TypeMatcher<dynamic>? originRoute,
  TypeMatcher<dynamic>? destinationRoute,
}) {
  var result = isA<BackwardTransition>();
  if (originRoute != null) {
    result = result.having(
      (it) => it.originRoute,
      'originRoute',
      originRoute,
    );
  }
  if (destinationRoute != null) {
    result = result.having(
      (it) => it.destinationRoute,
      'destinationRoute',
      destinationRoute,
    );
  }
  return result;
}

TypeMatcher<ForwardTransition> isForwardTransition({
  TypeMatcher<dynamic>? originRoute,
  TypeMatcher<dynamic>? destinationRoute,
}) {
  var result = isA<ForwardTransition>();
  if (originRoute != null) {
    result = result.having(
      (it) => it.originRoute,
      'originRoute',
      originRoute,
    );
  }
  if (destinationRoute != null) {
    result = result.having(
      (it) => it.destinationRoute,
      'destinationRoute',
      destinationRoute,
    );
  }
  return result;
}

TypeMatcher<TransitionCompleted> isTransitionCompleted({
  TypeMatcher<dynamic>? currentRoute,
}) {
  var result = isA<TransitionCompleted>();
  if (currentRoute != null) {
    result = result.having(
      (it) => it.currentRoute,
      'currentRoute',
      currentRoute,
    );
  }
  return result;
}

TypeMatcher<ModalRoute<dynamic>> isModalRoute({
  RouteSettings? settings,
}) {
  var result = isA<ModalRoute<dynamic>>();
  if (settings != null) {
    result = result.having(
      (it) => it.settings,
      'settings',
      settings,
    );
  }
  return result;
}

/// Returns a matcher that matches if an object is a sequence
/// of [double] values that are monotonically increasing or decreasing.
///
/// The matcher does not match if the sequence has less than two elements.
Matcher isMonotonic({required bool increasing}) =>
    _IsMonotonic(increasing: increasing);

class _IsMonotonic extends Matcher {
  const _IsMonotonic({required this.increasing});

  final bool increasing;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Iterable<double>) {
      return false;
    }

    final iterator = item.iterator;
    var itemCount = 0;
    double? previous;
    while (iterator.moveNext()) {
      itemCount++;
      final current = iterator.current;
      final diff = current - (previous ?? current);
      if ((increasing && diff < 0) || (!increasing && diff > 0)) {
        return false;
      }
      previous = current;
    }

    return itemCount > 1;
  }

  @override
  Description describe(Description description) =>
      description.add('monotonically increasing');
}
