import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:move_tracker/providers/accelerometer_sensor.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  List<double> _accelerometerValues = [];
  String _string = 'Start';

  @override
  void initState() {
    super.initState();
    hwSensor.listen().onData(
          (data) => setState(
            () {
              _accelerometerValues = [data.x, data.y, data.z];
            },
          ),
        );
  }

  @override
  void dispose() {
    super.dispose();
    hwSensor.cancel();
  }

  Widget _iosSettingsUI() {
    final userAccelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Log'),
      ),
      child: Center(
        child: Text(
          'UserAccelerometer: $userAccelerometer',
          style: const CupertinoTextThemeData().textStyle,
        ),
      ),
    );
  }

  Widget _androidSettingsUI() {
    final userAccelerometer =
        _accelerometerValues.map((double v) => v.toStringAsFixed(1)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log'),
      ),
      body: Center(
        child: Text('UserAccelerometer: $userAccelerometer'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _iosSettingsUI() : _androidSettingsUI();
  }
}
