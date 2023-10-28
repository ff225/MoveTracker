import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:move_tracker/data/models/accelerometer_data.dart';
import 'package:move_tracker/providers/ble_notifier.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

import '../constants.dart';
import '../firebase_options.dart';

class DatabaseMoveTracker {
  static const String _databaseName = 'accelerometer.db';

  static final DatabaseMoveTracker _database = DatabaseMoveTracker._internal();

  DatabaseMoveTracker._internal();

  static DatabaseMoveTracker get instance => _database;

  static sql.Database? _db;

  Future<sql.Database> get database async => _db ??= await init();

  Future<sql.Database> init() async {
    return await sql
        .openDatabase(path.join(await sql.getDatabasesPath(), _databaseName),
            onCreate: (db, version) async {
      await db.execute('CREATE TABLE ${Constants.tableDeviceAccelerometer} ('
          'timestamp TEXT NOT NULL,'
          'x TEXT NOT NULL,'
          'y TEXT NOT NULL,'
          'z TEXT NOT NULL,'
          'is_sent INTEGER NOT NULL'
          ')');

      await db.execute('CREATE TABLE ${Constants.tableMovesenseAccelerometer} ('
          'timestamp TEXT NOT NULL,'
          'x TEXT NOT NULL,'
          'y TEXT NOT NULL,'
          'z TEXT NOT NULL,'
          'is_sent INTEGER NOT NULL'
          ')');

      await db.execute('CREATE TABLE ${Constants.tableMovesenseInfo} ('
          'mac_address TEXT NOT NULL,'
          'serial_id TEXT NOT NULL,'
          'hz_logging INTEGER DEFAULT 13 NOT NULL,'
          'status TEXT NOT NULL'
          ')');
    }, version: 1);
  }

  // Operation on Accelerometer Data
  Future<void> insertAccelerometerData(
      {required DateTime timestamp,
      required List<double> xAxis,
      required List<double> yAxis,
      required List<double> zAxis,
      required String table}) async {
    var db = await instance.database;
    await db.insert(
        table,
        AccelerometerData(
          timestamp: timestamp,
          x: xAxis,
          y: yAxis,
          z: zAxis,
        ).toMap());
  }

  Future<List<AccelerometerData>> getDataFromDB({required String table}) async {
    var db = await instance.database;

    final List<Map<String, dynamic>> data =
        await db.query(table, where: 'is_sent = ?', whereArgs: [0]);

    return List.generate(data.length, (index) {
      return AccelerometerData(
        timestamp: DateTime.parse(data[index]['timestamp']),
        x: List<double>.from(
            data[index]['x'].split(", ").map((e) => double.parse(e))),
        y: List<double>.from(
            data[index]['y'].split(", ").map((e) => double.parse(e))),
        z: List<double>.from(
            data[index]['z'].split(", ").map((e) => double.parse(e))),
      );
    });
  }

  Future<void> updateAccelerometerInfo(String timestamp,
      {required String table}) async {
    var db = await instance.database;

    await db.update(table, {'is_sent': 1},
        where: 'timestamp = ?', whereArgs: [timestamp]);
  }

  Future<void> deleteAccelerometerTable({required String table}) async {
    var db = await instance.database;

    await db.delete(table, where: 'is_sent = ?', whereArgs: [1]);
  }

  Future<void> sendToCloud({required String table}) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    var db = FirebaseFirestore.instance;
    final list = await DatabaseMoveTracker.instance.getDataFromDB(table: table);
    log('$table, list length: ${list.length}');

    for (final element in list) {
      await db.collection(table).doc(element.timestamp.toIso8601String()).set(
        {
          'x': element.x,
          'y': element.y,
          'z': element.z,
        },
      ).whenComplete(
        () async => await DatabaseMoveTracker.instance.updateAccelerometerInfo(
          element.timestamp.toIso8601String(),
          table: table,
        ),
      );
    }
  }

  // Operation on Movesense

  Future<void> insertMovesenseInfo(BluetoothModel device) async {
    var db = await instance.database;

    var checkInfo = await db.query(Constants.tableMovesenseInfo,
        columns: ['mac_address'],
        where: 'mac_address = ?',
        whereArgs: [device.macAddress]);

    /*
    Casi da considerare:
    - Disconnessione dello stesso dispositivo -> non necessario scrivere sul db
    - Disconnessione dispositivo e connessione di un altro dispositivo -> necessario cancellare e riscrivere
     */

    if (checkInfo.isNotEmpty) {
      await updateConnectionStatus(device);
      return;
    }

    await db.delete(Constants.tableMovesenseInfo);

    log('store info about movesense...');
    db.insert(
      Constants.tableMovesenseInfo,
      {
        'mac_address': device.macAddress,
        'serial_id': device.serialId,
        'status': device.isConnected.name
      },
    );
  }

  // TODO riutilizzabile per cambiare frequenza logging
  Future<void> updateConnectionStatus(BluetoothModel device) async {
    var db = await instance.database;

    db.update(
      Constants.tableMovesenseInfo,
      {'status': device.isConnected.name},
      where: 'mac_address = ?',
      whereArgs: [device.macAddress],
    );
  }

  Future<BluetoothModel> getDevice() async {
    var db = await instance.database;
    var device = await db.query(Constants.tableMovesenseInfo);

    return device.isEmpty
        ? BluetoothModel('', '')
        : BluetoothModel(device[0]['mac_address'].toString(),
            device[0]['serial_id'].toString(),
            isConnected: device[0]['status'].toString() == 'connected'
                ? DeviceConnectionState.connected
                : DeviceConnectionState.disconnected);
  }

  Future<String> getMacAddress() async {
    var db = await instance.database;

    var result =
        await db.query(Constants.tableMovesenseInfo, columns: ['mac_address']);
    return result[0]['mac_address'].toString();
  }

  Future<String> getSerialId() async {
    var db = await instance.database;

    var result =
        await db.query(Constants.tableMovesenseInfo, columns: ['serial_id']);
    return result[0]['serial_id'].toString();
  }

  Future<void> deleteMovesenseInfo(BluetoothModel device) async {
    var db = await instance.database;

    log('delete info about movesense...');
    await db.delete(Constants.tableMovesenseInfo,
        where: 'serial_id = ?', whereArgs: [device.serialId]);
  }
}
