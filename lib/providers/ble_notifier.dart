import 'dart:async';
import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mdsflutter/Mds.dart';

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

  void startScan() {
    /*
    Mds.get("suunto://214530002602/Comm/Ble/Peers", "{}", (p0, p1) {
      print(p0);
      print(p1);
    }, (p0, p1) {
      print("error: $p0");
      print("error: $p1");
    });

     */

    final List<BluetoothModel> discoveredDevice = [];
    Mds.startScan((nameDevice, macAddr) {
      if (discoveredDevice.isEmpty) {
        discoveredDevice.add(BluetoothModel(macAddr!, nameDevice!));
      }
      for (var element in discoveredDevice) {
        if (element.id != macAddr!) {
          discoveredDevice.add(BluetoothModel(macAddr, nameDevice!));
        }
      }
      state = discoveredDevice;
    });

    Timer(
      const Duration(seconds: 10),
      () => Mds.stopScan(),
    );
    /*_ble.statusStream.listen((event) {
      state = [];
      switch (event) {
        case BleStatus.unknown:
          print('unknown');
        case BleStatus.unauthorized:
          print('unauthorized');
        case BleStatus.ready:
          final searching =
              _ble.scanForDevices(withServices: []).listen((event) {
            //print("${event.name}, ${event.id}");
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
    });*/
  }
}

class BleConnectNotifier extends StateNotifier<BluetoothModel> {
  BleConnectNotifier() : super(BluetoothModel('', ''));

  final _ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connection;

  void connectToDevice(BluetoothModel device) {
    Mds.connect(device.id, (p0) {
      print(p0);
      device.isConnected = DeviceConnectionState.connected;
      state = device;
    }, () {}, () {});
    /*_connection = _ble
        .connectToAdvertisingDevice(
      id: device.id,
      withServices: [],
      prescanDuration: const Duration(seconds: 5),
    )
        .listen((event) {
      print(event.connectionState.name);

      state = BluetoothModel(device.id, device.name,
          isConnected: event.connectionState);

      if (event.connectionState == DeviceConnectionState.connected) {
        Mds.connect(event.deviceId, (p0) {
          print("connected");
        }, () {}, () {});
      }
    });
     */
  }

  void disconnectFromDevice(BluetoothModel device) {
    Mds.disconnect(device.id);
    device.isConnected = DeviceConnectionState.disconnected;
    state = device;
    _connection?.cancel().whenComplete(() => BluetoothModel('', ''));
  }
}

final bleProvider = StateNotifierProvider<BleNotifier, List<BluetoothModel>>(
    (ref) => BleNotifier());

final bleConnectProvider =
    StateNotifierProvider<BleConnectNotifier, BluetoothModel>(
        (ref) => BleConnectNotifier());
