import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

sealed class RouteTransitionStatus {
  const RouteTransitionStatus();
}

class NoRoute extends RouteTransitionStatus {
  const NoRoute();

  @override
  String toString() => '$NoRoute';
}

class TransitionCompleted extends RouteTransitionStatus {
  TransitionCompleted({required this.currentRoute});

  final ModalRoute<dynamic> currentRoute;

  @override
  String toString() =>
      '$TransitionCompleted${(currentRoute: describeIdentity(currentRoute))}';
}

class ForwardTransition extends RouteTransitionStatus {
  ForwardTransition({
    required this.originRoute,
    required this.destinationRoute,
    required this.animation,
  });

  final ModalRoute<dynamic> originRoute;
  final ModalRoute<dynamic> destinationRoute;
  final Animation<double> animation;

  @override
  String toString() => '$ForwardTransition${(
        originRoute: describeIdentity(originRoute),
        destinationRoute: describeIdentity(destinationRoute),
      )}';
}

class BackwardTransition extends RouteTransitionStatus {
  BackwardTransition({
    required this.originRoute,
    required this.destinationRoute,
    required this.animation,
  });

  final ModalRoute<dynamic> originRoute;
  final ModalRoute<dynamic> destinationRoute;
  final Animation<double> animation;

  @override
  String toString() => '$BackwardTransition${(
        originRoute: describeIdentity(originRoute),
        destinationRoute: describeIdentity(destinationRoute),
      )}';
}

class UserGestureTransition extends RouteTransitionStatus {
  UserGestureTransition({
    required this.currentRoute,
    required this.previousRoute,
    required this.animation,
  });

  final ModalRoute<dynamic> currentRoute;
  final ModalRoute<dynamic> previousRoute;
  final Animation<double> animation;

  @override
  String toString() => '$UserGestureTransition${(
        currentRoute: describeIdentity(currentRoute),
        previousRoute: describeIdentity(previousRoute),
      )}';
}
