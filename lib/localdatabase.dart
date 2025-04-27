import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            taskInput TEXT,
            createdAt TEXT,
            endDateTime TEXT,
            status TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    await db.insert(
      'tasks',
      {
        'id': task['id'],
        'taskInput': task['taskInput'],
        'createdAt': task['createdAt'],
        'endDateTime': task['endDateTime'],
        'status': task['status'],
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if already exists
    );
  }

  static Future<bool> taskExists(String id) async {
    final db = await database;
    final result = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }
}
