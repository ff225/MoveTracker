import 'dart:developer';

import 'package:mdsflutter/Mds.dart';
import 'package:move_tracker/constants.dart';
import 'package:move_tracker/data/database.dart';
import 'package:workmanager/workmanager.dart';

class Movesense {
  Future<void> setTime() async {
    var serialId = await DatabaseMoveTracker.instance.getSerialId();
    log(DateTime.timestamp().toUtc().microsecondsSinceEpoch.toString());
    MdsAsync.put(Mds.createRequestUri(serialId, '/Time/'),
        '''{"value": ${DateTime.timestamp().toUtc().microsecondsSinceEpoch}}''');
  }

  // TODO potrei tornare un'informazione per gestire il caso in cui ci siano errori in fase di configurazione.
  Future<void> configLogger({int hz = 13}) async {
    var serialId = await DatabaseMoveTracker.instance.getSerialId();

    // alla prima connessione/riconnessione è necessario fare il flush della memoria
    await saveDataToDatabase();

    await setTime();

    var state = await getLogState();

    log('state is: $state');

    if (state.contains('error')) return;

    state.contains('3') ? await setLogState(state: 2) : null;

    var jsonConfig = '''{
                            "config": {
                                "dataEntries": {
                                    "dataEntry": [
                                        {
                                            "path": "/Meas/Acc/$hz"
                                        }
                                    ]
                                }
                            }
                        }''';

    var response = await MdsAsync.put(
            Mds.createRequestUri(serialId, '/Mem/DataLogger/Config/'),
            jsonConfig)
        .then<String>((_) => setLogState(state: 3), onError: (error, _) {
      MdsError status = error as MdsError;
      log('error: ${status.error}');
      return 'error: ${status.status}';
      //
    });

    print('response: $response');
    if (!response.contains('error')) {
      Workmanager().registerPeriodicTask(
        'from-movesense-to-database',
        'save-movesense-data',
        initialDelay: const Duration(minutes: 5),
        frequency: const Duration(minutes: 15),
      );

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
    }
  }

  Future<String> getLogState() async {
    var serialId = await DatabaseMoveTracker.instance.getSerialId();

    return MdsAsync.get(
            Mds.createRequestUri(serialId, '/Mem/DataLogger/State'), '')
        .then((state) => state.toString(), onError: (error, _) {
      MdsError status = error as MdsError;
      log('error: ${status.error}');
      return 'error: ${status.status}';
    });
  }

  Future<String> setLogState({required int state}) async {
    var serialId = await DatabaseMoveTracker.instance.getSerialId();

    var jsonConfig = '''{"newState": $state}''';

    return MdsAsync.put(
            Mds.createRequestUri(serialId, '/Mem/DataLogger/State/'),
            jsonConfig)
        .then<String>((_) => 'newState: $state', onError: (error, _) {
      MdsError status = error as MdsError;
      log('error: ${status.error}');
      return 'error: ${status.status}';
    });
  }

  Future<void> saveDataToDatabase() async {
    var serialId = await DatabaseMoveTracker.instance.getSerialId();

    var state = await getLogState();

    if (state.contains('error')) return;

    // stop logging
    state.contains('3') ? await setLogState(state: 2) : null;

    // Get id
    var elements = await MdsAsync.get(
            Mds.createRequestUri(serialId, '/Mem/Logbook/Entries/'), '')
        .then((id) => id['elements'] /*[0]['Id'].toString()*/,
            onError: (error, _) {
      MdsError status = error as MdsError;
      log('error: ${status.error}');
      return 'error: ${status.status}';
    });

    if (elements.contains('error')) return;

    for (var element in elements) {
      log(element.toString());
      var idEntry = element['Id'];
      //log("id: $id");
      //var id = entryId['elements'][0]['Id'];

      List<double> xValues = [];
      List<double> yValues = [];
      List<double> zValues = [];

      // Store value in x, y, z list else 'error'
      var values = await MdsAsync.get(
              Mds.createRequestUri(
                  'MDS/Logbook/$serialId', '/byId/$idEntry/Data'),
              '')
          .then((values) {
        for (var accData in values['Meas']['Acc']) {
          for (var value in accData['ArrayAcc']) {
            log("x: ${double.parse(value['x'].toString())}, y: ${value['y']}, z: ${value['z']}");

            xValues.add(double.parse(value['x'].toString()));
            yValues.add(double.parse(value['y'].toString()));
            zValues.add(double.parse(value['z'].toString()));
          }
        }
        return 'done';
      }, onError: (error, _) {
        MdsError status = error as MdsError;
        log('error: ${status.error}');
        return 'error: ${status.status}';
      });

      if (values.contains('error')) return;

      //"suunto://MDS/Logbook/214530002554/byId/$id/Data", "");
/*
    for (var accData in values['Meas']['Acc']) {
      for (var value in accData['ArrayAcc']) {
        log("x: ${double.parse(value['x'].toString())}, y: ${value['y']}, z: ${value['z']}");

        xValues.add(double.parse(value['x'].toString()));
        yValues.add(double.parse(value['y'].toString()));
        zValues.add(double.parse(value['z'].toString()));
      }
    }

 */
      log("x: ${xValues.length},y: ${yValues.length},z: ${zValues.length} ");

      // Store values on db
      log('store data to ${Constants.tableMovesenseAccelerometer}...');
      await DatabaseMoveTracker.instance.insertAccelerometerData(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
                  element['ModificationTimestamp'] * 1000)
              .toUtc(),
          xAxis: xValues,
          yAxis: yValues,
          zAxis: zValues,
          table: Constants.tableMovesenseAccelerometer);
    }

    // Delete entry
    log('delete entries... ');
    await MdsAsync.del(
      Mds.createRequestUri(serialId, '/Mem/Logbook/Entries/'),
      //"suunto://214530002554/Mem/Logbook/Entries/",
      "",
    );

    // Restart Logging

    log('restart logging: ${await setLogState(state: 3)}');
  }
}
