import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/firebase_options.dart';
import 'package:move_tracker/providers/accelerometer_sensor.dart';

class AccelerometerService {
  final service = FlutterBackgroundService();


  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance serviceInstance) async {
    DartPluginRegistrant.ensureInitialized();
    final hwSensor = AccelerometerSensor();

    serviceInstance.on('sendToCloud').listen((event) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      var db = FirebaseFirestore.instance;
      final list = await DatabaseMoveTracker.instance.getDataFromDB();
      print(list.length);

      for (final element in list) {
        await db.collection('accelerometerData').add(
          {
            'timestamp': element.timestamp,
            'x': element.x,
            'y': element.y,
            'z': element.z,
          },
        ).whenComplete(
          () async => await DatabaseMoveTracker.instance.updateInfo(
            element.timestamp.toIso8601String(),
          ),
        );
      }

      hwSensor.cancel();
      hwSensor.listen();
    });

    serviceInstance.on('viewData').listen((event) async {
      if (hwSensor.xAxis.isNotEmpty ||
          hwSensor.yAxis.isNotEmpty ||
          hwSensor.zAxis.isNotEmpty) {
        await DatabaseMoveTracker.instance.insert(
            xAxis: hwSensor.xAxis,
            yAxis: hwSensor.yAxis,
            zAxis: hwSensor.zAxis);
      }
      print(
          "x_length: ${hwSensor.xAxis.length}\ny_length: ${hwSensor.yAxis.length}\nz_length: ${hwSensor.zAxis.length}");
      hwSensor.pause();
      print('pause');
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
