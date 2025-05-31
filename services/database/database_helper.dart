//services/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:echo_remind/models/reminder.dart';

class DatabaseHelper {
  static const _databaseName = "EchoRemind.db";
  static const _databaseVersion = 1; // Increment this version if you change the schema (e.g., add 'radius')
  static const table = 'reminders';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade for schema changes
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        triggerType TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        radius REAL
      )
    ''');
  }

  // Handle database schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      // This is handled by onCreate if version is 1 from scratch
    }
    if (oldVersion < 2) {
      // Example: If we upgrade to version 2 and add a new column 'radius'
      // await db.execute('ALTER TABLE $table ADD COLUMN radius REAL');
    }
    // Add other upgrade scripts for future versions
  }

  // CRUD Operations

  Future<int> insertReminder(Reminder reminder) async {
    Database db = await instance.database;
    return await db.insert(table, reminder.toMap());
  }

  Future<List<Reminder>> getAllReminders() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return Reminder.fromMap(maps[i]);
    });
  }

  Future<Reminder?> getReminder(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return Reminder.fromMap(results.first);
    }
    return null;
  }

  Future<int> updateReminder(Reminder reminder) async {
    Database db = await instance.database;
    return await db.update(
      table,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    Database db = await instance.database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Reminder>> getActiveReminders() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'isActive = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) {
      return Reminder.fromMap(maps[i]);
    });
  }

  Future<int> getActiveReminderCount() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) FROM $table WHERE isActive = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
