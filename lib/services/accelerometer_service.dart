import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:move_tracker/constants.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/providers/accelerometer_sensor.dart';

class AccelerometerService {
  final service = FlutterBackgroundService();

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance serviceInstance) async {
    DartPluginRegistrant.ensureInitialized();
    final hwSensor = AccelerometerSensor();

    serviceInstance.on('sendToCloud').listen((event) async {
      // Non è necessario che sia await perché i dati sono sul db
      log('send data from ${Constants.tableDeviceAccelerometer} to cloud');
      DatabaseMoveTracker.instance
          .sendToCloud(table: Constants.tableDeviceAccelerometer);

      // Non sono necessari perché qui va a pescare direttamente dal db
      //hwSensor.cancel();
      //hwSensor.listen();
    });

    serviceInstance.on('saveDataToDB').listen((event) async {
      log('service in pause');
      hwSensor.pause();
      if (hwSensor.xAxis.isNotEmpty ||
          hwSensor.yAxis.isNotEmpty ||
          hwSensor.zAxis.isNotEmpty) {
        log('store data to ${Constants.tableDeviceAccelerometer}...');
        await DatabaseMoveTracker.instance.insertAccelerometerData(
          xAxis: hwSensor.xAxis,
          yAxis: hwSensor.yAxis,
          zAxis: hwSensor.zAxis,
          table: Constants.tableDeviceAccelerometer,
        );
      }
      log("x_length: ${hwSensor.xAxis.length}\ny_length: ${hwSensor.yAxis.length}\nz_length: ${hwSensor.zAxis.length}");
      log('restart service');
      hwSensor.cancel();
      hwSensor.listen();
    });

    serviceInstance.on('stopService').listen((event) {
      hwSensor.cancel();
      serviceInstance.stopSelf();
    });

    hwSensor.listen();
  }

  Future<void> initService() async {
    service.configure(
      iosConfiguration: IosConfiguration(autoStart: true),
      androidConfiguration: AndroidConfiguration(
          autoStart: true,
          onStart: onStart,
          autoStartOnBoot: true,
          isForegroundMode: true),
    );
  }
}
