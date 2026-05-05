import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:actitvities/services/notification_service.dart';
import 'package:actitvities/models/task.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint('Opening database at path: $path');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        password TEXT,
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        note TEXT,
        date TEXT,
        startTime TEXT,
        endTime TEXT,
        color TEXT,
        user_name TEXT
      )
    ''');
    debugPrint('Database tables created successfully');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN user_name TEXT');
      debugPrint('Database upgraded to version $newVersion');
    }
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    final id = await db.insert('users', user);
    debugPrint('User inserted with ID: $id');
    return id;
  }

  Future<Map<String, dynamic>?> getUser(String name) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertTask(Map<String, dynamic> task, String userName) async {
    task['user_name'] = userName;
    final db = await database;
    final id = await db.insert('tasks', task);
    debugPrint('Task inserted with ID: $id, User: $userName');

    final taskObj = Task.fromMap(task);
    await NotificationService.instance.scheduleTaskNotification(
      task: taskObj,
      notificationId: id,
    );

    // Schedule only **start time notification**
    await NotificationService.instance.scheduleTaskNotification(
      task: taskObj,
      notificationId: id,
    );

    return id;
  }

  Future<List<Map<String, dynamic>>> getTasks(String userName) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'user_name = ?',
      whereArgs: [userName],
    );
    debugPrint('Tasks retrieved for user $userName: ${result.length} tasks');
    return result;
  }

  Future<int> deleteTask(int id, String userName) async {
    final db = await database;
    final count = await db.delete(
      'tasks',
      where: 'id = ? AND user_name = ?',
      whereArgs: [id, userName],
    );
    debugPrint('Task deleted with ID: $id for user: $userName');

    await NotificationService.instance.cancelNotification(id);

    return count;
  }
}
