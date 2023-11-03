import 'dart:async';
import 'dart:developer';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/providers/movesense.dart';
import 'package:workmanager/workmanager.dart';

class BluetoothModel {
  BluetoothModel(
    this.macAddress,
    this.serialId, {
    this.isConnected = DeviceConnectionState.disconnected,
    this.frequencyHz = 13,
  });

  final String macAddress;
  final String serialId;
  DeviceConnectionState isConnected;
  int frequencyHz;
}

class BleNotifier extends StateNotifier<List<BluetoothModel>> {
  BleNotifier() : super([]);

/*
  final _ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connection;

  void status() async {
    Mds.del("suunto://214530002602/Comm/Ble/Adv", "{}", (p0, p1) {
      print(p0);
      print(p1);
    }, (p0, p1) {
      print("error: $p0");
      print("error: $p1");
    });
  }

  void connect() async {
    Mds.post("suunto://214530002602/Comm/Ble/Adv", "{}", (p0, p1) {
      print(p0);
      print(p1);
    }, (p0, p1) {
      print("error: $p0");
      print("error: $p1");
    });
  }
*/
  void startScan() {
    state = [];
    MdsAsync.startScan(
      (serialId, macAddress) {
        BluetoothModel bm =
            BluetoothModel(macAddress!, serialId!.split(' ')[1]);

        if (state.isEmpty) state = [...state, bm];

        if (!state.any((element) => element.macAddress == bm.macAddress)) {
          state = [...state, bm];
        }
      },
    );
  }
}

class BleConnectNotifier extends StateNotifier<BluetoothModel> {
  BleConnectNotifier() : super(BluetoothModel('', ''));

  //final _ble = FlutterReactiveBle();
  //StreamSubscription<ConnectionStateUpdate>? _connection;
  void connectToDevice(BluetoothModel device, {bool init = false}) {
    //AccelerometerService().service.invoke('stopSub');
    //firstConnection = init;
    Mds.connect(device.macAddress, (p0) async {
      log('first connection? ${init.toString()}');
      //AccelerometerService().service.invoke('stopSub');
      //AccelerometerService().service.invoke('startSub');
      //print(p0);
      //AccelerometerService().service.invoke('cancelSub');
      if (init) {
        device.isConnected = DeviceConnectionState.connected;
        await DatabaseMoveTracker.instance.insertMovesenseInfo(device);
        await Movesense().configLogger();
      }

      // Start logging
      //log('inside Connect');

      //AccelerometerService().service.invoke('restartSub');
      state = device;
    }, () async {
      init = false;
      //AccelerometerService().service.invoke('stopSub');
      //AccelerometerService().service.invoke('startSub');
      device.isConnected = DeviceConnectionState.disconnected;
      await DatabaseMoveTracker.instance
          .updateInfoMovesense(device, hzLogging: device.frequencyHz);
      state = device;
    }, () {});
  }

  Future<void> disconnectFromDevice(BluetoothModel device,
      {bool forgetDevice = false}) async {
    // STOP logging? Ha senso perché se dal device decidiamo di disconnetterci
    // dal dispostivo, non ha senso tenere attivo il log e quindi consumare batteria.
    //AccelerometerService().service.invoke('stopSub');

    await Movesense().setLogState(state: 2);

    Mds.disconnect(device.macAddress);

    // Delete worker
    await Workmanager().cancelByUniqueName('from-movesense-to-database');
    await Workmanager().cancelByUniqueName('from-movesense-to-cloud');

    device.isConnected = DeviceConnectionState.disconnected;
    forgetDevice
        ? await DatabaseMoveTracker.instance.deleteMovesenseInfo(device)
        : await DatabaseMoveTracker.instance
            .updateInfoMovesense(device, hzLogging: device.frequencyHz);

    log('forgetDevice? $forgetDevice');
    forgetDevice
        ? Workmanager().cancelByUniqueName('notification-device-disconnected')
        : null;
    state = forgetDevice ? BluetoothModel('', '') : device;
  }

  Future<void> config() async {
    state = await DatabaseMoveTracker.instance.getDevice();
  }
}

final bleProvider = StateNotifierProvider<BleNotifier, List<BluetoothModel>>(
    (ref) => BleNotifier());

final bleConnectProvider =
    StateNotifierProvider<BleConnectNotifier, BluetoothModel>(
        (ref) => BleConnectNotifier());
