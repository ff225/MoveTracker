import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:move_tracker/constants.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:move_tracker/providers/movesense.dart';
import 'package:move_tracker/screens/home_page.dart';
import 'package:move_tracker/services/accelerometer_service.dart';
import 'package:workmanager/workmanager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/launch_background');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid));
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await DatabaseMoveTracker.instance.init();
  await AccelerometerService().initService();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  Workmanager().registerPeriodicTask(
    'from-device-to-cloud',
    'send-device-data',
    existingWorkPolicy: ExistingWorkPolicy.append,
    constraints: Constraints(
      networkType: NetworkType.connected,
      //requiresDeviceIdle: true,
      //requiresBatteryNotLow: true,
    ),
    initialDelay: const Duration(minutes: 10),
    frequency: const Duration(minutes: 15),
  );

  Workmanager().registerPeriodicTask(
    'from-device-to-database',
    'save-device-data',
    existingWorkPolicy: ExistingWorkPolicy.append,
/*    constraints: Constraints(
      networkType: NetworkType.connected,
    ),*/
    initialDelay: const Duration(minutes: 5),
    frequency: const Duration(minutes: 15),
  );
  Workmanager().registerPeriodicTask(
    'clear-database',
    'clear-database',
    frequency: const Duration(hours: 1),
    initialDelay: const Duration(minutes: 30),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(bleConnectProvider.notifier).config();
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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (taskName, inputData) async {
      switch (taskName) {
        case 'save-device-data':
          AccelerometerService().service.invoke('saveDataToDB');
          break;
        case 'send-device-data':
          AccelerometerService().service.invoke('sendToCloud');
          break;
        case 'save-movesense-data':
          await Movesense().saveDataToDatabase();
          break;
        case 'send-movesense-data':
          await DatabaseMoveTracker.instance
              .sendToCloud(table: Constants.tableMovesenseAccelerometer);
          break;
        case 'clear-database':
          await DatabaseMoveTracker.instance.deleteAccelerometerTable(
              table: Constants.tableDeviceAccelerometer);
          await DatabaseMoveTracker.instance.deleteAccelerometerTable(
              table: Constants.tableMovesenseAccelerometer);
          break;
        case 'device-disconnected':
          AndroidNotificationDetails androidNotificationDetails =
              AndroidNotificationDetails(
            Constants.notificationChannelId,
            Constants.notificationChannelId,
            channelDescription:
                "Notifiche per informare l'utente sullo stato della connessione al sensore.",
            importance: Importance.max,
            priority: Priority.high,
          );
          NotificationDetails notificationDetails =
              NotificationDetails(android: androidNotificationDetails);
          flutterLocalNotificationsPlugin.show(0, "Dispositivo disconnesso",
              ('Il sensore non è più conesso..'), notificationDetails);
          break;
      }

      return Future.value(true);
    },
  );
}
