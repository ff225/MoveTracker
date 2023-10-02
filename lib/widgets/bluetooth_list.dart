import 'package:flutter/material.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:move_tracker/widgets/bluetooth_item.dart';

class BluetoothList extends StatelessWidget {
  const BluetoothList(this.devices, {super.key});

  final List<BluetoothModel> devices;

  @override
  Widget build(BuildContext context) {
    return devices.isEmpty
        ? const Center(
            child: Text('Cerca dispositivi'),
          )
        : ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) => BluetoothItem(
              devices[index],
            ),
          );
  }
}
