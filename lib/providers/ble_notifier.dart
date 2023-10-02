import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BluetoothModel {
  BluetoothModel(this.id, this.name,
      {this.isConnected = DeviceConnectionState.disconnected, this.data = 0});

  final String id;
  final String name;
  DeviceConnectionState isConnected;
  dynamic data;
}

class BleNotifier extends StateNotifier<List<BluetoothModel>> {
  BleNotifier() : super([]);

  final _ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connection;

  void startScan() {
    final List<BluetoothModel> discoveredDevice = [];
    _ble.statusStream.listen((event) {
      state = [];
      switch (event) {
        case BleStatus.unknown:
          print('unknown');
        case BleStatus.unauthorized:
          print('unauthorized');
        case BleStatus.ready:
          final searching =
              _ble.scanForDevices(withServices: []).listen((event) {
            if (event.name != '' &&
                discoveredDevice
                    .where((element) => element.id == event.id)
                    .isEmpty) {
              discoveredDevice.add(BluetoothModel(event.id, event.name));
            }
          });
          Timer(Duration(seconds: 5), () {
            state = discoveredDevice;
            print(state);
            searching.cancel();
          });
          break;
        default:
          print(event);
      }
      ;
    });
  }
}

class BleConnectNotifier extends StateNotifier<BluetoothModel> {
  BleConnectNotifier() : super(BluetoothModel('', ''));

  final _ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connection;

  void connectToDevice(BluetoothModel device) {
    _connection = _ble
        .connectToAdvertisingDevice(
      id: device.id,
      withServices: [],
      prescanDuration: const Duration(seconds: 5),
    )
        .listen((event) {
      print(event.connectionState.name);
      state = BluetoothModel(device.id, device.name,
          isConnected: event.connectionState);
    });
  }

  void disconnectFromDevice() {
    _connection?.cancel().whenComplete(() => BluetoothModel('', ''));
  }
}

final bleProvider = StateNotifierProvider<BleNotifier, List<BluetoothModel>>(
    (ref) => BleNotifier());

final bleConnectProvider =
    StateNotifierProvider<BleConnectNotifier, BluetoothModel>(
        (ref) => BleConnectNotifier());
