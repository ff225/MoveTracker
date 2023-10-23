import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mdsflutter/Mds.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

import '../widgets/bluetooth_list.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(bleProvider);
    return Scaffold(
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

                var jsonConfig = '''{
                            "config": {
                                "dataEntries": {
                                    "dataEntry": [
                                        {
                                            "path": "/Meas/Acc/13"
                                        }
                                    ]
                                }
                            }
                        }''';

                Mds.put(
                    "suunto://214530002602/Mem/DataLogger/Config/", jsonConfig,
                    (p0, p1) {
                  log(p0);
                }, (p0, p1) {
                  log("error: $p0");
                });
              },
              icon: const Icon(Icons.subscriptions)),
          IconButton(
              onPressed: () {
                Mds.put("suunto://214530002602/Mem/DataLogger/State/",
                    '''{"newState": 3}''', (p0, p1) {
                  log(p0);

                  Workmanager().registerPeriodicTask(
                    'from-movesense-to-database',
                    'save-movesense-data',
                    initialDelay: const Duration(minutes: 5),
                    frequency: const Duration(minutes: 15),
                  );
                }, (p0, p1) {
                  log("error: $p0");
                });
              },
              icon: const Icon(Icons.real_estate_agent)),
          IconButton(
              onPressed: () async {
                await [
                  Permission.bluetoothScan,
                  Permission.bluetoothConnect,
                  Permission.location
                ].request();
                ref.read(bleConnectProvider.notifier).disconnectFromDevice(
                    BluetoothModel(("0C:8C:DC:3E:EE:DB"), "name"));
              },
              icon: const Icon(Icons.bluetooth_disabled)),
          IconButton(
            onPressed: () async {
              await [
                Permission.bluetoothScan,
                Permission.bluetoothConnect,
                Permission.location
              ].request();

              Workmanager().registerOneOffTask(
                  'save-data-device-test', 'save-device-data');
              Workmanager().registerOneOffTask(
                  'send-data-device-test', 'send-device-data');
              Workmanager()
                  .registerOneOffTask('clear-database-test', 'clear-database');
            },
            /*
              Map<String, dynamic> response = {};
              Mds.put("suunto://214530002602/Mem/DataLogger/State/",
                  '''{"newState": 2}''', (p0, p1) {
                print(p0);
              }, (p0, p1) {
                print("error: $p0");
              });

              Mds.get("suunto://214530002602/Mem/Logbook/Entries/", "",
                  (p0, p1) {
                print(p0);
                response = jsonDecode(p0);
                print(response);
                print("id: ${response['Content']['elements'][0]['Id']}");

                Mds.get(
                  "suunto://MDS/Logbook/214530002602/byId/${response['Content']['elements'][0]['Id']}/Data",
                  "",
                  (p0, p1) {
                    Map<String, dynamic> json = jsonDecode(p0)['Meas'];

                    List<dynamic> accList = json['Acc'];

                    for (var acc in accList) {
                      print(acc['ArrayAcc']);
                      print(acc['Timestamp']);
                    }
                  },
                  (p0, p1) {},
                );
/*
                Mds.del("suunto://214530002602/Mem/Logbook/Entries/", "",
                    (p0, p1) {
                  print(p0);
                }, (p0, p1) {
                  print("error: $p0");
                });

 */
                //print(response);
                /*Mds.get(
                    "suunto://MDS/Logbook/214530002602/byId/${response['Id']}/Data",
                    "", (p0, p1) {
                  print(p0);
                }, (p0, p1) {
                  print("error: $p0");
                });

                 */
              }, (p0, p1) {});
            },*/
            icon: const Icon(Icons.ac_unit),
          ),
          IconButton(
              onPressed: () async {
                await [
                  Permission.bluetoothScan,
                  Permission.bluetoothConnect,
                  Permission.location
                ].request();

                Mds.del("suunto://214530002602/Mem/Logbook/Entries/", "",
                    (p0, p1) {
                  log(jsonEncode(p0));
                }, (p0, p1) {
                  log("error: $p0");
                });
                //ref.read(bleProvider.notifier).status();
              },
              icon: const Icon(Icons.bluetooth)),
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
    );
  }
}

/*

 */
