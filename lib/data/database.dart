import 'package:move_tracker/data/models/accelerometer_data.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

class Database {
  static const String _databaseName = 'accelerometer.db';
  static const String _tableName = 'accelerometer_data';

  static final Database _database = Database._internal();

  Database._internal();

  static Database get instance => _database;

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
}
