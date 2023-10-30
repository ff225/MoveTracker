import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:move_tracker/widgets/movesense_settings.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/bluetooth_list.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(bleProvider);
    final providerb = ref.watch(bleConnectProvider);
    ref.read(bleConnectProvider.notifier).config();
    return providerb.macAddress.isEmpty
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Impostazioni'),
              actions: [
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
          )
        : const MovesenseSettings();
  }
}
