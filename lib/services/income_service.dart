import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/income_model.dart';

class IncomeService {
  final DBHelper _dbHelper = DBHelper();

  // ===============================
  // ADD INCOME
  // ===============================
  Future<void> addIncome(Income income) async {
    final db = await _dbHelper.database;
    await db.insert(
      'income',
      income.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===============================
  // FETCH ALL INCOME
  // ===============================
  Future<List<Income>> getAllIncome() async {
    final db = await _dbHelper.database;
    final result =
        await db.query('income', orderBy: 'date DESC');

    return result.map((e) => Income.fromMap(e)).toList();
  }

  // ===============================
  // FETCH INCOME BY SOURCE ✅ ADDED
  // ===============================
  Future<List<Income>> getIncomeBySource(String source) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'income',
      where: 'source = ?',
      whereArgs: [source],
      orderBy: 'date DESC',
    );

    return result.map((e) => Income.fromMap(e)).toList();
  }

  // ===============================
  // UPDATE INCOME ✅ NEW
  // ===============================
  Future<void> updateIncome(Income income) async {
    final db = await _dbHelper.database;

    await db.update(
      'income',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  // ===============================
  // DELETE INCOME
  // ===============================
  Future<void> deleteIncome(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'income',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===============================
  // TOTAL FOR DASHBOARD (MONTH)
  // ===============================
  Future<double> getThisMonthIncome() async {
    final db = await _dbHelper.database;
    final month =
        DateTime.now().toIso8601String().substring(0, 7);

    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount),0) AS total
      FROM income
      WHERE substr(date,1,7) = ?
      ''',
      [month],
    );

    return (result.first['total'] as num).toDouble();
  }
}
