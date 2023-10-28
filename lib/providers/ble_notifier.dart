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
  });

  final String macAddress;
  final String serialId;
  DeviceConnectionState isConnected;
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

  // TODO potrei fare una chiamata al db per inizializzare lo stato
  //final _ble = FlutterReactiveBle();
  //StreamSubscription<ConnectionStateUpdate>? _connection;
  void connectToDevice(BluetoothModel device) {
    Mds.connect(device.macAddress, (p0) async {
      print(p0);
      device.isConnected = DeviceConnectionState.connected;

      // check che nel momento della disconnessione "improvvisa"
      //  e poi riconnessione non scriva nuovamente informazioni presenti nel db.

      // se colleghiamo un dispositivo con un serialId/macaddr diverso,
      // prima va cancellato il contenuto.
      await DatabaseMoveTracker.instance.insertMovesenseInfo(device);
      // Start logging
      Movesense().configLogger();
      state = device;
    }, () async {
      device.isConnected = DeviceConnectionState.disconnected;
      await DatabaseMoveTracker.instance.updateConnectionStatus(device);
      state = device;
    }, () {});
  }

  Future<void> disconnectFromDevice(BluetoothModel device,
      {bool forgetDevice = false}) async {
    // STOP logging? Ha senso perché se dal device decidiamo di disconnetterci
    // dal dispostivo, non ha senso tenere attivo il log e quindi consumare batteria.

    await Movesense().setLogState(state: 2);

    Mds.disconnect(device.macAddress);

    // Delete worker
    // TODO capire perché non funziona
    await Workmanager().cancelByUniqueName('from-movesense-to-database');
    await Workmanager().cancelByUniqueName('from-movesense-to-cloud');

    device.isConnected = DeviceConnectionState.disconnected;
    forgetDevice
        ? await DatabaseMoveTracker.instance.deleteMovesenseInfo(device)
        : await DatabaseMoveTracker.instance.updateConnectionStatus(device);

    log('forgetDevice? $forgetDevice');
    state = forgetDevice ? BluetoothModel('', '') : device;
    //_connection?.cancel().whenComplete(() => BluetoothModel('', ''));
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
