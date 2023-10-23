import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:move_tracker/constants.dart';
import 'package:move_tracker/data/database.dart';
import 'package:move_tracker/screens/home_page.dart';
import 'package:move_tracker/services/accelerometer_service.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AccelerometerService().initService();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  // TODO hardcoded movesense serial
  Workmanager().registerPeriodicTask(
    'from-movesense-to-cloud',
    'send-movesense-data',
    existingWorkPolicy: ExistingWorkPolicy.append,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    initialDelay: const Duration(minutes: 10),
    frequency: const Duration(minutes: 15),
  );

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
        case 'save-device-data':
          AccelerometerService().service.invoke('saveDataToDB');
          break;
        case 'send-device-data':
          AccelerometerService().service.invoke('sendToCloud');
          break;
        case 'save-movesense-data':
          //Stop logging
          await MdsAsync.put("suunto://214530002602/Mem/DataLogger/State/",
              '''{"newState": 2}''');

          // Get entry id
          var entryId = await MdsAsync.get(
              "suunto://214530002602/Mem/Logbook/Entries/", "");

          log("id: ${entryId['Content']['elements'][0]['Id']}");
          var id = entryId['Content']['elements'][0]['Id'];
          var values = await MdsAsync.get(
              "suunto://MDS/Logbook/214530002602/byId/$id/Data", "");
          List<double> xValues = [];
          List<double> yValues = [];
          List<double> zValues = [];
          for (var accData in values['Meas']['Acc']) {
            for (var value in accData['ArrayAcc']) {
              log("x: ${double.parse(value['x'].toString())}, y: ${value['y']}, z: ${value['z']}");

              xValues.add(double.parse(value['x'].toString()));
              yValues.add(double.parse(value['y'].toString()));
              zValues.add(double.parse(value['z'].toString()));
            }
          }
          log("x: ${xValues.length},y: ${yValues.length},z: ${zValues.length} ");

          // Store values on db
          log("store in db...");
          await DatabaseMoveTracker.instance.insert(
              xAxis: xValues,
              yAxis: yValues,
              zAxis: zValues,
              table: Constants.tableMovesenseAccelerometer);

          // Delete entry
          await MdsAsync.del(
            "suunto://214530002602/Mem/Logbook/Entries/",
            "",
          );

          // Restart Logging
          await MdsAsync.put("suunto://214530002602/Mem/DataLogger/State/",
              '''{"newState": 3}''');
          break;
        case 'send-movesense-data':
          DatabaseMoveTracker.instance
              .sendToCloud(table: Constants.tableMovesenseAccelerometer);
          /*await Firebase.initializeApp(
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
          }*/
          break;
        case 'clear-database':
          await DatabaseMoveTracker.instance
              .deleteData(table: Constants.tableDeviceAccelerometer);
          await DatabaseMoveTracker.instance
              .deleteData(table: Constants.tableMovesenseAccelerometer);
          break;
      }
      return Future.value(true);
    },
  );
}
