import 'package:move_tracker/data/models/accelerometer_data.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

class DatabaseMoveTracker {
  static const String _databaseName = 'accelerometer.db';
  static const String _tableName = 'accelerometer_data';
  static const String _tableNameDevice = 'movesense_acc_data';

  static final DatabaseMoveTracker _database = DatabaseMoveTracker._internal();

  DatabaseMoveTracker._internal();

  static DatabaseMoveTracker get instance => _database;

  static sql.Database? _db;

  Future<sql.Database> get database async => _db ??= await init();

  Future<sql.Database> init() async {
    return await sql
        .openDatabase(path.join(await sql.getDatabasesPath(), _databaseName),
            onCreate: (db, version) async {
      await db.execute('CREATE TABLE $_tableName ('
          'timestamp TEXT NOT NULL,'
          'x TEXT NOT NULL,'
          'y TEXT NOT NULL,'
          'z TEXT NOT NULL,'
          'isSent INTEGER NOT NULL'
          ')');

      await db.execute('CREATE TABLE $_tableNameDevice ('
          'timestamp TEXT NOT NULL,'
          'x TEXT NOT NULL,'
          'y TEXT NOT NULL,'
          'z TEXT NOT NULL,'
          'isSent INTEGER NOT NULL'
          ')');
      //db.execute('CREATE TABLE $_tableNameDevice ('')');
    }, version: 1);
  }

  Future<void> insert(
      {required List<double> xAxis,
      required List<double> yAxis,
      required List<double> zAxis,
      String tableName = _tableName}) async {
    var db = await instance.database;
    await db.insert(
        tableName,
        AccelerometerData(
          timestamp: DateTime.timestamp(),
          x: xAxis,
          y: yAxis,
          z: zAxis,
        ).toMap());
  }

  Future<List<AccelerometerData>> getDataFromDB(
      {String tableName = _tableName}) async {
    var db = await instance.database;

    final List<Map<String, dynamic>> data =
        await db.query(tableName, where: 'isSent = ?', whereArgs: [0]);

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

  Future<void> updateInfo(String timestamp,
      {String tableName = _tableName}) async {
    var db = await instance.database;

    await db.update(tableName, {'isSent': 1},
        where: 'timestamp = ?', whereArgs: [timestamp]);
  }
}
