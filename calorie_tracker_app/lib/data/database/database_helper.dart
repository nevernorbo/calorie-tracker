import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('calorie_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        image_path TEXT,
        prediction REAL,
        user_adjustment REAL
      )
    ''');
  }

  Future<int> insertEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('logs', entry);
  }

  Future<List<Map<String, dynamic>>> getAllEntries() async {
    final db = await database;
    return await db.query('logs', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getEntriesByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await db.query(
      'logs',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>>
  getEntriesGroupedByDay() async {
    final entries = await getAllEntries();
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (final entry in entries) {
      final timestamp = DateTime.parse(entry['timestamp'] as String);
      final dateKey = DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (grouped.containsKey(dateKey)) {
        grouped[dateKey]!.add(entry);
      } else {
        grouped[dateKey] = [entry];
      }
    }

    return grouped;
  }

  Future<int> updateEntry(int id, Map<String, dynamic> entry) async {
    final db = await database;
    return await db.update('logs', entry, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
