import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/providers/accelerometer_sensor.dart';
import 'package:move_tracker/screens/home_page.dart';

final service = FlutterBackgroundService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initService();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> onStart(ServiceInstance serviceInstance) async {
  DartPluginRegistrant.ensureInitialized();

  serviceInstance.on('stopService').listen((event) {
    serviceInstance.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 10), (timer) {
    print('Hello');
    print(hwSensor.xAxis.length);
    print(hwSensor.yAxis.length);
    print(hwSensor.zAxis.length);
    serviceInstance.stopSelf();
  });
  hwSensor.listen();
}

Future<void> initService() async {
  service.configure(
    iosConfiguration: IosConfiguration(autoStart: true),
    androidConfiguration: AndroidConfiguration(
        onStart: onStart, autoStartOnBoot: true, isForegroundMode: false),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Move Tracker',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePageScreen('Move Tracker'),
    );
  }
}
