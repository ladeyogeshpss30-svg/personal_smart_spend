import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';

class CategoryNoteService {
  final DBHelper _dbHelper = DBHelper();

  // ===============================
  // FETCH NOTES BY CATEGORY (MAX 5)
  // ===============================
  Future<List<String>> getNotesByCategory(int categoryId) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'category_notes',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'id',
      limit: 5,
    );

    return result.map((e) => e['note'] as String).toList();
  }

  // ===============================
  // INSERT DEFAULT NOTES (ONCE)
  // ===============================
  Future<void> insertDefaultNotesIfNeeded(
    int categoryId,
    List<String> notes,
  ) async {
    final db = await _dbHelper.database;

    final existing = await db.query(
      'category_notes',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );

    if (existing.isNotEmpty) return;

    for (final note in notes) {
      await db.insert(
        'category_notes',
        {
          'category_id': categoryId,
          'note': note,
          'is_default': 1,
        },
      );
    }
  }

  // ===============================
  // ADD NOTE (UI ENFORCES LIMIT)
  // ===============================
  Future<void> addNote({
    required int categoryId,
    required String note,
  }) async {
    final db = await _dbHelper.database;

    await db.insert(
      'category_notes',
      {
        'category_id': categoryId,
        'note': note,
        'is_default': 0,
      },
    );
  }

  // ===============================
  // DELETE ALL NOTES FOR A CATEGORY
  // ===============================
  Future<void> deleteNotesByCategory(int categoryId) async {
    final db = await _dbHelper.database;

    await db.delete(
      'category_notes',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // ===============================
  // OPTIONAL: COUNT NOTES (UI USE)
  // ===============================
  Future<int> getNoteCount(int categoryId) async {
    final db = await _dbHelper.database;

    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM category_notes WHERE category_id = ?',
            [categoryId],
          ),
        ) ??
        0;

    return count;
  }
}
