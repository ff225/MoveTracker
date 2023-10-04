import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:move_tracker/providers/accelerometer_sensor.dart';

class AccelerometerService {

  final service = FlutterBackgroundService();

  static Future<void> onStart(ServiceInstance serviceInstance) async {
    DartPluginRegistrant.ensureInitialized();
    final hwSensor = AccelerometerSensor();

    serviceInstance.on('viewData').listen((event) {
      print(
          "x_length: ${hwSensor.xAxis.length}\ny_length: ${hwSensor.yAxis.length}\nz_length: ${hwSensor.zAxis.length}");
      serviceInstance.stopSelf();
      print("stop");
    });

    serviceInstance.on('stopService').listen((event) {
      hwSensor.cancel();
      serviceInstance.stopSelf();
    });

    Timer.periodic(const Duration(seconds: 10), (timer) {
      print('Hello');

      //serviceInstance.stopSelf();
    });
    hwSensor.listen();
  }

  Future<void> initService() async {
    service.configure(
      iosConfiguration: IosConfiguration(autoStart: true),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
          onStart: onStart, autoStartOnBoot: true, isForegroundMode: true),
    );
  }
}