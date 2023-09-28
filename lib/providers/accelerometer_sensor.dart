import 'dart:async';
import 'dart:developer' as dev;

import 'package:sensors_plus/sensors_plus.dart';

final AccelerometerSensor hwSensor = AccelerometerSensor();

class AccelerometerSensor {
  late Stream<AccelerometerEvent> _stream;
  late StreamSubscription<AccelerometerEvent> _sub;

  AccelerometerSensor() {
    _stream = accelerometerEvents;
  }

  StreamSubscription<AccelerometerEvent> listen() {
    _sub = _stream.listen(
      (event) {
        dev.log('${event.x}, ${event.y}, ${event.z}');
      },
      cancelOnError: true,
    );
    return _sub;
  }

  void cancel() async {
    await _sub.cancel();
  }
}
