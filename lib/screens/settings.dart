import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/bluetooth_list.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(bleProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        actions: [
          IconButton(
            onPressed: () async {
              Map<Permission, PermissionStatus> statuses = await [
                Permission.bluetoothScan,
                Permission.bluetoothConnect,
                Permission.location
              ].request();

              if (await Permission.bluetoothScan.isGranted &&
                  await Permission.bluetoothConnect.isGranted) {
                print('Permission granted');
                ref.read(bleProvider.notifier).startScan();
              } else {
                print('Permission not granted');
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

/*

 */
