import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Reads genuine accelerometer data. If the sensor is not available on the
/// device the service simply reports unavailable — no values are invented.
class MotionService {
  StreamSubscription<AccelerometerEvent>? _sub;

  bool _available = false;
  bool get available => _available;

  /// Absolute deviation of total acceleration from gravity (m/s²).
  double _magnitude = 0;
  double get magnitude => _magnitude;

  /// Change in device orientation vector between samples.
  double _orientationDelta = 0;
  double get orientationDelta => _orientationDelta;

  double? _lastX;
  double? _lastY;
  double? _lastZ;

  Future<bool> start() async {
    if (_sub != null) return _available;
    try {
      _sub = accelerometerEventStream().listen(
        (e) {
          _available = true;
          final total = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
          _magnitude = (total - 9.81).abs();
          if (_lastX != null) {
            _orientationDelta = ((e.x - _lastX!).abs() +
                    (e.y - _lastY!).abs() +
                    (e.z - _lastZ!).abs()) /
                3;
          }
          _lastX = e.x;
          _lastY = e.y;
          _lastZ = e.z;
        },
        onError: (_) {
          _available = false;
        },
        cancelOnError: false,
      );
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _magnitude = 0;
    _orientationDelta = 0;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
