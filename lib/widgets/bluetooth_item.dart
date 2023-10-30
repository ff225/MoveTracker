import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ble_notifier.dart';

class BluetoothItem extends ConsumerWidget {
  const BluetoothItem(this.device, {super.key});

  final BluetoothModel device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(bleConnectProvider);
    return ListTile(
      title: Text(device.macAddress),
      subtitle: Text(device.serialId),
      onTap: () {
        if (device.serialId != status.serialId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Devi prima connetterti a: ${device.serialId}'),
            ),
          );
        } /* else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                if (device.name == status[0].name &&
                    status[0].isConnected == DeviceConnectionState.disconnected) {
                  ref
                      .read(bleProvider.notifier)
                      .disconnectFromDevice(/*device*/);
                }
                return const ManageBluetoothScreen();
              },
            ),
          );
        }*/
      },
      trailing: TextButton.icon(
        onPressed: () {
          if (status.isConnected == DeviceConnectionState.disconnected) {
            ref.read(bleConnectProvider.notifier).connectToDevice(device);
          } else {
            ref.read(bleConnectProvider.notifier).disconnectFromDevice(device);
          }
        },
        /*
            .read(bluetoothConnectionProvider.notifier)
            .disconnectFromDevice(device),*/

        icon: Icon(status.isConnected == DeviceConnectionState.disconnected
            ? Icons.bluetooth
            : Icons.bluetooth_connected),
        label: Text(status.isConnected
                .name /*status.macAddress == device.macAddress
            ? status.isConnected.name
            : DeviceConnectionState.disconnected.name*/
            ),
      ),
    );
  }
}
