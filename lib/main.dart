import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/screens/home_page.dart';
import 'package:move_tracker/services/accelerometer_service.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AccelerometerService().initService();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // TODO check che la tabella non restituisca campo vuoto.
  Workmanager().registerPeriodicTask(
    'fromMovesenseToFirestore',
    'send-data-acc',
    existingWorkPolicy: ExistingWorkPolicy.append,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    initialDelay: const Duration(minutes: 10),
    frequency: const Duration(minutes: 15),
  );
  /*
  Workmanager().registerPeriodicTask(
    'listenAccelerometer',
    'send-value',
    initialDelay: const Duration(minutes: 5),
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
   */

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
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

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (taskName, inputData) async {
      switch (taskName) {
        case 'task-listen':
          AccelerometerService().service.invoke('stopService');
          //print(hwSensor.yAxis.length);
          print('task-listen');
          AccelerometerService().service.startService();
          break;
        case 'send-value':
          AccelerometerService().service.invoke('viewData');
          AccelerometerService().service.invoke('sendToCloud');
          //service.startService();
          break;
        case 'read-from-movesense':
          //Stop logging
          await MdsAsync.put("suunto://214530002602/Mem/DataLogger/State/",
              '''{"newState": 2}''');

          // Get entry id
          var entryId = await MdsAsync.get(
              "suunto://214530002602/Mem/Logbook/Entries/", "");

          print("id: ${entryId['Content']['elements'][0]['Id']}");
          var id = entryId['Content']['elements'][0]['Id'];
          var values = await MdsAsync.get(
              "suunto://MDS/Logbook/214530002602/byId/$id/Data", "");
          List<double> xValues = [];
          List<double> yValues = [];
          List<double> zValues = [];
          for (var accData in values['Meas']['Acc']) {
            for (var value in accData['ArrayAcc']) {
              print(
                  "x: ${double.parse(value['x'].toString())}, y: ${value['y']}, z: ${value['z']}");

              xValues.add(double.parse(value['x'].toString()));
              yValues.add(double.parse(value['y'].toString()));
              zValues.add(double.parse(value['z'].toString()));
            }
          }
          print(
              "x: ${xValues.length},y: ${yValues.length},z: ${zValues.length} ");

          // Store values on db
          print("store in db...");
          await DatabaseMoveTracker.instance.insert(
              xAxis: xValues,
              yAxis: yValues,
              zAxis: zValues,
              tableName: "movesense_acc_data");

          // Delete  entry
          await MdsAsync.del(
            "suunto://214530002602/Mem/Logbook/Entries/",
            "",
          );

          // Restart Logging
          await MdsAsync.put("suunto://214530002602/Mem/DataLogger/State/",
              '''{"newState": 3}''');
          break;
        case 'send-data-acc':
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          var db = FirebaseFirestore.instance;
          final list = await DatabaseMoveTracker.instance
              .getDataFromDB(tableName: "movesense_acc_data");
          print(list.length);

          for (final element in list) {
            await db
                .collection('accelerometerDataMovesense')
                .doc(element.timestamp.toIso8601String())
                .set(
              {
                'x': element.x,
                'y': element.y,
                'z': element.z,
              },
            ).whenComplete(
              () async => await DatabaseMoveTracker.instance.updateInfo(
                tableName: "movesense_acc_data",
                element.timestamp.toIso8601String(),
              ),
            );

            break;
          }
      }
      return Future.value(true);
    },
  );
}
