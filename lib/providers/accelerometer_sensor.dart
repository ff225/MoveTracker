import 'dart:async';
import 'dart:developer' as dev;

import 'package:sensors_plus/sensors_plus.dart';

//final AccelerometerSensor hwSensor = AccelerometerSensor();

class AccelerometerSensor {
  late Stream<AccelerometerEvent> _stream;
  late StreamSubscription<AccelerometerEvent> _sub;
  final List<double> _xAxis = [];
  final List<double> _yAxis = [];
  final List<double> _zAxis = [];

  List<double> get xAxis => _xAxis;

  List<double> get yAxis => _yAxis;

  List<double> get zAxis => _zAxis;

  AccelerometerSensor() {
    _stream = accelerometerEvents;
  }

  StreamSubscription<AccelerometerEvent> listen() {
    _sub = _stream.listen(
      (event) {
        _xAxis.add(event.x);
        _yAxis.add(event.y);
        _zAxis.add(event.z);
        dev.log('${event.x}, ${event.y}, ${event.z}');
      },
      cancelOnError: true,
    );
    return _sub;
  }

  void cancel() async {
    await _sub.cancel();
    _xAxis.clear();
    _yAxis.clear();
    _zAxis.clear();
  }
}
