import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/constants.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:move_tracker/providers/movesense.dart';
import 'package:move_tracker/services/accelerometer_service.dart';

class MovesenseSettings extends ConsumerWidget {
  const MovesenseSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(bleConnectProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Movesense ${device.serialId}'),
        /*actions: [
          if (device.isConnected == DeviceConnectionState.connected)
            IconButton(
                onPressed: () async {
                  await [
                    Permission.bluetoothScan,
                    Permission.bluetoothConnect,
                    Permission.location
                  ].request();
                  //ref
                  //  .read(bleConnectProvider.notifier)
                  //.disconnectFromDevice(device);
                },
                icon: const Icon(Icons.bluetooth_disabled)),
        ],*/
      ),
      body: device.isConnected == DeviceConnectionState.connected
          ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Imposta frequenza di logging'),
                    onTap: () => showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => WillPopScope(
                          onWillPop: () => Future.value(false),
                          child: DropdownDialog(device)),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Flush della memoria'),
                    onTap: () async {
                      AccelerometerService().service.invoke('saveDataToDB');
                      await Movesense().saveDataToDatabase();
                      await DatabaseMoveTracker.instance.sendToCloud(
                          table: Constants.tableMovesenseAccelerometer);
                      await DatabaseMoveTracker.instance.sendToCloud(
                          table: Constants.tableDeviceAccelerometer);
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

class DropdownDialog extends StatefulWidget {
  DropdownDialog(this.device, {super.key});

  BluetoothModel device;

  @override
  State<DropdownDialog> createState() {
    return _DropdownDialogState();
  }
}

class _DropdownDialogState extends State<DropdownDialog> {
  int selectedValue = 13;
  bool isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Configura la frequenza di logging.'),
            DropdownButton<int>(
              value: selectedValue,
              items: const <DropdownMenuItem<int>>[
                DropdownMenuItem<int>(
                  value: 13,
                  child: Text('13'),
                ),
                DropdownMenuItem<int>(
                  value: 26,
                  child: Text('26'),
                ),
                DropdownMenuItem<int>(
                  value: 52,
                  child: Text('52'),
                ),
              ],
              onChanged: (int? value) {
                log('value: $value');
                setState(() {
                  selectedValue = value!;
                  log('selectedValue: $selectedValue');
                });
              },
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isEnabled
                      ? () {
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: isEnabled
                      ? () async {
                          setState(() {
                            isEnabled = false;
                          });
                          await DatabaseMoveTracker.instance
                              .updateInfoMovesense(widget.device,
                                  hzLogging: selectedValue);
                          await Movesense()
                              .configLogger()
                              .then((value) => Navigator.pop(context));
                        }
                      : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
