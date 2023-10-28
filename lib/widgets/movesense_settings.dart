import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/constants.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:move_tracker/providers/movesense.dart';
import 'package:move_tracker/services/accelerometer_service.dart';
import 'package:permission_handler/permission_handler.dart';

class MovesenseSettings extends ConsumerWidget {
  const MovesenseSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(bleConnectProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Movesense ${device.serialId}'),
        actions: [
          // TODO rimuovere dopo test
          if (device.isConnected == DeviceConnectionState.connected)
            IconButton(
                onPressed: () async {
                  await [
                    Permission.bluetoothScan,
                    Permission.bluetoothConnect,
                    Permission.location
                  ].request();
                  ref
                      .read(bleConnectProvider.notifier)
                      .disconnectFromDevice(device);
                },
                icon: const Icon(Icons.bluetooth_disabled)),
        ],
      ),
      body: device.isConnected == DeviceConnectionState.connected
          ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Card(
                    child: ListTile(
                  title: const Text('Imposta frequenza di logging'),
                  onTap: () {

                  },
                )),
                Card(
                  child: ListTile(
                    title: const Text('Flush della memoria'),
                    onTap: () async {
                      AccelerometerService().service.invoke('saveDataToDB');
                      await Movesense().saveDataToDatabase();
                      await DatabaseMoveTracker.instance.sendToCloud(
                          table: Constants.tableMovesenseAccelerometer);
                      await DatabaseMoveTracker.instance
                          .sendToCloud(table: Constants.tableDeviceAccelerometer);
                    },
                    trailing: const Icon(Icons.save_alt),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Disconnetti'),
                    onTap: () async {
                      ref
                          .read(bleConnectProvider.notifier)
                          .disconnectFromDevice(device);
                    },
                    trailing: const Icon(Icons.bluetooth_disabled),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Dimentica dispositivo'),
                    onTap: () async {
                      ref
                          .read(bleConnectProvider.notifier)
                          .disconnectFromDevice(device, forgetDevice: true);
                    },
                    trailing: const Icon(Icons.delete_forever),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: const Text('Connetti'),
                    onPressed: () {
                      ref
                          .read(bleConnectProvider.notifier)
                          .connectToDevice(device);
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Dimentica dispositivo'),
                    onPressed: () {
                      ref
                          .read(bleConnectProvider.notifier)
                          .disconnectFromDevice(device, forgetDevice: true);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
