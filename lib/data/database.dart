import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:move_tracker/data/models/accelerometer_data.dart';
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
          'isSent INTEGER NOT NULL'
          ')');

      await db.execute('CREATE TABLE ${Constants.tableMovesenseAccelerometer} ('
          'timestamp TEXT NOT NULL,'
          'x TEXT NOT NULL,'
          'y TEXT NOT NULL,'
          'z TEXT NOT NULL,'
          'isSent INTEGER NOT NULL'
          ')');
    }, version: 1);
  }

  Future<void> insert(
      {required List<double> xAxis,
      required List<double> yAxis,
      required List<double> zAxis,
      required String table}) async {
    var db = await instance.database;
    await db.insert(
        table,
        AccelerometerData(
          timestamp: DateTime.timestamp(),
          x: xAxis,
          y: yAxis,
          z: zAxis,
        ).toMap());
  }

  Future<List<AccelerometerData>> getDataFromDB({required String table}) async {
    var db = await instance.database;

    final List<Map<String, dynamic>> data =
        await db.query(table, where: 'isSent = ?', whereArgs: [0]);

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

  Future<void> updateInfo(String timestamp, {required String table}) async {
    var db = await instance.database;

    await db.update(table, {'isSent': 1},
        where: 'timestamp = ?', whereArgs: [timestamp]);
  }

  Future<void> deleteData({required String table}) async {
    var db = await instance.database;

    await db.delete(table, where: 'isSent = ?', whereArgs: [1]);
  }

  Future<void> sendToCloud({required String table}) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    var db = FirebaseFirestore.instance;
    final list = await DatabaseMoveTracker.instance.getDataFromDB(table: table);
    log('list length: ${list.length}');

    for (final element in list) {
      await db.collection(table).doc(element.timestamp.toIso8601String()).set(
        {
          'x': element.x,
          'y': element.y,
          'z': element.z,
        },
      ).whenComplete(
        () async => await DatabaseMoveTracker.instance.updateInfo(
          element.timestamp.toIso8601String(),
          table: table,
        ),
      );
    }
  }
}
