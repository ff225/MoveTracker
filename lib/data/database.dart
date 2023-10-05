import 'package:move_tracker/data/models/accelerometer_data.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

class DatabaseAccelerometer {
  static const String _databaseName = 'accelerometer.db';
  static const String _tableName = 'accelerometer_data';

  static final DatabaseAccelerometer _database =
      DatabaseAccelerometer._internal();

  DatabaseAccelerometer._internal();

  static DatabaseAccelerometer get instance => _database;

  static sql.Database? _db;

  Future<sql.Database> get database async => _db ??= await init();

  Future<sql.Database> init() async {
    return await sql
        .openDatabase(path.join(await sql.getDatabasesPath(), _databaseName),
            onCreate: (db, version) {
      return db.execute('CREATE TABLE $_tableName ('
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
      required List<double> zAxis}) async {
    var db = await instance.database;
    await db.insert(
        _tableName,
        AccelerometerData(
          timestamp: DateTime.timestamp(),
          x: xAxis,
          y: yAxis,
          z: zAxis,
        ).toMap());
  }

  Future<List<AccelerometerData>> getDataFromDB() async {
    var db = await instance.database;

    final List<Map<String, dynamic>> data =
        await db.query(_tableName, where: 'isSent = ?', whereArgs: [0]);

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

  Future<void> updateInfo(String timestamp) async {
    var db = await instance.database;

    await db.update(_tableName, {'isSent': 1},
        where: 'timestamp = ?', whereArgs: [timestamp]);
  }
}
