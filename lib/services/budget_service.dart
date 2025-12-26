import 'package:sqflite/sqflite.dart';

import '../database/db_helper.dart';

class BudgetService {
  final DBHelper _dbHelper = DBHelper();

  // ===============================
  // CATEGORY BUDGET METHODS
  // ===============================

  Future<void> setCategoryBudget({
    required int categoryId,
    required String month, // YYYY-MM
    required double amount,
  }) async {
    final db = await _dbHelper.database;

    await db.insert(
      'budgets',
      {
        'category_id': categoryId,
        'month': month,
        'amount': amount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getCategoryBudget({
    required int categoryId,
    required String month,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'budgets',
      where: 'category_id = ? AND month = ?',
      whereArgs: [categoryId, month],
      limit: 1,
    );

    if (result.isEmpty) return 0.0;
    return (result.first['amount'] as num).toDouble();
  }

  Future<double> getCategorySpent({
    required int categoryId,
    required String month,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE category_id = ?
        AND substr(date, 1, 7) = ?
      ''',
      [categoryId, month],
    );

    return (result.first['total'] as num).toDouble();
  }

  // ===============================
  // 🔴 RESET CATEGORY BUDGET (FIXED)
  // ===============================
  Future<void> resetCategoryBudget({
    required int categoryId,
    required String month,
  }) async {
    final db = await _dbHelper.database;

    await db.delete(
      'budgets',
      where: 'category_id = ? AND month = ?',
      whereArgs: [categoryId, month],
    );
  }

  // ===============================
  // OVERALL BUDGET METHODS
  // ===============================

  /// Set overall budget (daily or monthly)
  /// period: YYYY-MM or YYYY-MM-DD
  Future<void> setOverallBudget({
    required String period,
    required double amount,
  }) async {
    final db = await _dbHelper.database;

    await db.insert(
      'budgets',
      {
        'category_id': null,
        'month': period,
        'amount': amount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get overall budget
  Future<double> getOverallBudget(String period) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'budgets',
      where: 'category_id IS NULL AND month = ?',
      whereArgs: [period],
      limit: 1,
    );

    if (result.isEmpty) return 0.0;
    return (result.first['amount'] as num).toDouble();
  }

  /// Get overall spent (daily or monthly)
  Future<double> getOverallSpent(String period) async {
    final db = await _dbHelper.database;

    final isDaily = period.length == 10; // YYYY-MM-DD

    final result = await db.rawQuery(
      isDaily
          ? '''
          SELECT IFNULL(SUM(amount),0) AS total
          FROM expenses
          WHERE date = ?
          '''
          : '''
          SELECT IFNULL(SUM(amount),0) AS total
          FROM expenses
          WHERE substr(date,1,7) = ?
          ''',
      [period],
    );

    return (result.first['total'] as num).toDouble();
  }

  // ===============================
  // 🔴 RESET OVERALL BUDGET (FIXED)
  // ===============================
  Future<void> resetOverallBudget(String period) async {
    final db = await _dbHelper.database;

    await db.delete(
      'budgets',
      where: 'category_id IS NULL AND month = ?',
      whereArgs: [period],
    );
  }

  // ===============================
  // 🔔 ALERT TRACKING (NULL SAFE)
  // ===============================

  Future<bool> isAlertAlreadyTriggered({
    int? categoryId,
    required String period,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'alerts',
      where: categoryId == null
          ? 'category_id IS NULL AND period = ?'
          : 'category_id = ? AND period = ?',
      whereArgs: categoryId == null
          ? [period]
          : [categoryId, period],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> markAlertTriggered({
    int? categoryId,
    required String period,
  }) async {
    final db = await _dbHelper.database;

    await db.insert(
      'alerts',
      {
        'category_id': categoryId,
        'threshold': 100,
        'period': period,
        'triggered_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
