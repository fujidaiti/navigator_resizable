import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

extension AndroidBackGestureSimulation on WidgetTester {
  Future<void> startAndroidBackGesture({
    required List<double> touchOffset,
    double progress = 0.0,
    int swipeEdge = 0,
  }) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': touchOffset,
          'progress': progress,
          'swipeEdge': swipeEdge,
        }),
      ),
      (ByteData? _) {},
    );
  }

  Future<void> updateAndroidBackGestureProgress({
    required double x,
    required double y,
    required double progress,
    int swipeEdge = 0,
  }) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('updateBackGestureProgress', <String, dynamic>{
          'x': x,
          'y': y,
          'progress': progress,
          'swipeEdge': swipeEdge,
        }),
      ),
      (ByteData? _) {},
    );
  }

  Future<void> commitAndroidBackGesture() async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('commitBackGesture'),
      ),
      (ByteData? _) {},
    );
  }

  Future<void> cancelAndroidBackGesture() async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('cancelBackGesture'),
      ),
      (ByteData? _) {},
    );
  }
}
