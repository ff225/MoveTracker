import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/constants.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:move_tracker/providers/movesense.dart';
import 'package:move_tracker/services/accelerometer_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/bluetooth_list.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(bleProvider);
    final providerb = ref.watch(bleConnectProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        actions: [
          IconButton(
              onPressed: () async {
                AccelerometerService().service.invoke('saveDataToDB');
                await Movesense().saveDataToDatabase();
                await DatabaseMoveTracker.instance
                    .sendToCloud(table: Constants.tableMovesenseAccelerometer);
                await DatabaseMoveTracker.instance
                    .sendToCloud(table: Constants.tableDeviceAccelerometer);
              },
              icon: const Icon(Icons.save_alt)),
          IconButton(
              onPressed: () async {
                await [
                  Permission.bluetoothScan,
                  Permission.bluetoothConnect,
                  Permission.location
                ].request();
                var macAddr =
                    await DatabaseMoveTracker.instance.getMacAddress();
                log('mac address: $macAddr');
                ref
                    .read(bleConnectProvider.notifier)
                    .disconnectFromDevice(BluetoothModel(macAddr, "name"));
              },
              icon: const Icon(Icons.bluetooth_disabled)),
          if (providerb.isConnected == DeviceConnectionState.disconnected)
            IconButton(
              onPressed: () async {
                await [
                  Permission.bluetoothScan,
                  Permission.bluetoothConnect,
                  Permission.location
                ].request();

                if (await Permission.bluetoothScan.isGranted &&
                    await Permission.bluetoothConnect.isGranted) {
                  log('Permission granted');
                  ref.read(bleProvider.notifier).startScan();
                } else {
                  log('Permission not granted');
                }
              },
              icon: const Icon(Icons.refresh_outlined),
            ),
        ],
      ),
      body: BluetoothList(provider),
    );
  }
}
