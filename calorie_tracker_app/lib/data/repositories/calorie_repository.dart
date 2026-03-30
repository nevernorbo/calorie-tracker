import '../database/database_helper.dart';
import '../models/calorie_entry.dart';

class CalorieRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> saveEntry(CalorieEntry entry) async {
    final map = entry.toMap();
    map.remove('id');
    return await _dbHelper.insertEntry(map);
  }

  Future<List<CalorieEntry>> getAllEntries() async {
    final maps = await _dbHelper.getAllEntries();
    return maps.map((map) => CalorieEntry.fromMap(map)).toList();
  }

  Future<List<CalorieEntry>> getEntriesByDate(DateTime date) async {
    final maps = await _dbHelper.getEntriesByDate(date);
    return maps.map((map) => CalorieEntry.fromMap(map)).toList();
  }

  Future<Map<DateTime, List<CalorieEntry>>> getEntriesGroupedByDay() async {
    final maps = await _dbHelper.getEntriesGroupedByDay();
    final Map<DateTime, List<CalorieEntry>> result = {};

    for (final entry in maps.entries) {
      result[entry.key] = entry.value
          .map((map) => CalorieEntry.fromMap(map))
          .toList();
    }

    return result;
  }

  Future<int> updateEntry(CalorieEntry entry) async {
    if (entry.id == null) throw Exception('Cannot update entry without id');
    return await _dbHelper.updateEntry(entry.id!, entry.toMap());
  }

  Future<int> deleteEntry(int id) async {
    return await _dbHelper.deleteEntry(id);
  }
}
