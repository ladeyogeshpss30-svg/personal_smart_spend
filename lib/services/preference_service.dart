import 'package:sqflite/sqflite.dart';

import '../database/db_helper.dart';

class PreferenceService {
  final DBHelper _dbHelper = DBHelper();

  Future<void> setUsername(String name) async {
    final db = await _dbHelper.database;
    await db.insert(
      'preferences',
      {'key': 'username', 'value': name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> getUsername() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'preferences',
      where: 'key = ?',
      whereArgs: ['username'],
      limit: 1,
    );

    if (result.isEmpty) return 'User';
    return result.first['value'] as String;
  }
}
