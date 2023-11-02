import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:move_tracker/constants.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/providers/accelerometer_sensor.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:move_tracker/providers/movesense.dart';

class AccelerometerService {
  final service = FlutterBackgroundService();

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance serviceInstance) async {
    DartPluginRegistrant.ensureInitialized();
    final hwSensor = AccelerometerSensor();

    log('Accelerometer service started');
    BluetoothModel device = await DatabaseMoveTracker.instance.getDevice();

    if (device.serialId.isNotEmpty) {
      Mds.connect(device.macAddress, (p0) {
        log('from service inside Connect');
      }, () {}, () {});
    }

    MdsAsync.subscribe('suunto://MDS/ConnectingDevices', "{}")
        .listen((event) async {
      device = await DatabaseMoveTracker.instance.getDevice();
      log('message: $event');
      log('state: ${event['Body']['State']}');
      if (event['Body']['State'] == 'Disconnected' &&
          device.macAddress.isNotEmpty) {
        device.isConnected = DeviceConnectionState.disconnected;
        await DatabaseMoveTracker.instance.updateInfoMovesense(device);
        // TODO notifiche
      } else if (event['Body']['State'] == 'FinishConnect' &&
          device.macAddress.isNotEmpty) {
        log('inside FinishConnect');
        device.isConnected = DeviceConnectionState.connected;
        await DatabaseMoveTracker.instance.updateInfoMovesense(device);
        Movesense().configLogger();
      }
    });
/*
    serviceInstance.on('startSub').listen((event) {
      log('restart subscription');
      x = MdsAsync.subscribe('suunto://MDS/ConnectingDevices', "{}")
          .listen((event) async {
        device = await DatabaseMoveTracker.instance.getDevice();
        log('message: $event');
        log('state: ${event['Body']['State']}');
        if (event['Body']['State'] == 'Disconnected' &&
            device.macAddress.isNotEmpty) {
          device.isConnected = DeviceConnectionState.disconnected;
          await DatabaseMoveTracker.instance.updateInfoMovesense(device);
          // TODO notifiche
        } else if (event['Body']['State'] == 'FinishConnect' &&
            device.macAddress.isNotEmpty) {
          log('inside FinishConnect');
          device.isConnected = DeviceConnectionState.connected;
          await DatabaseMoveTracker.instance.updateInfoMovesense(device);
          Movesense().configLogger();
        }
      });
    });

    serviceInstance.on('stopSub').listen((event) async {
      log('stop subscription');
      await x.cancel();
    });
*/
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
          timestamp: DateTime.timestamp().toUtc(),
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
