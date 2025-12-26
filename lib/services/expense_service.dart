import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../database/db_helper.dart';
import '../models/expense_model.dart';
import '../services/budget_service.dart';
import '../services/alert_service.dart';
import '../services/in_app_alert.dart';
import '../core/enums/analytics_time_frame.dart';

class ExpenseService {
  final DBHelper _dbHelper = DBHelper();

  // =====================================================
  // INSERT EXPENSE
  // =====================================================
  Future<void> addExpense(Expense expense) async {
    final db = await _dbHelper.database;

    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _checkBudgetAndNotify(expense);
  }

  // =====================================================
  // FETCH ALL EXPENSES
  // =====================================================
  Future<List<Expense>> getAllExpenses() async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );

    return result.map((e) => Expense.fromMap(e)).toList();
  }

  // =====================================================
  // FETCH EXPENSES BY TIME FRAME
  // =====================================================
  Future<List<Expense>> getExpensesByTimeFrame(
    AnalyticsTimeFrame? timeFrame,
  ) async {
    final db = await _dbHelper.database;

    final where = _buildDateWhereClause(timeFrame);

    final result = await db.query(
      'expenses',
      where: where,
      orderBy: 'date DESC',
    );

    return result.map((e) => Expense.fromMap(e)).toList();
  }

  // =====================================================
  // ✅ FETCH EXPENSES BY CATEGORY ID + TIME FRAME (FINAL)
  // =====================================================
  Future<List<Expense>> getExpensesByCategoryId(
    int categoryId,
    AnalyticsTimeFrame? timeFrame,
  ) async {
    final db = await _dbHelper.database;

    final dateWhere = _buildDateWhereClause(timeFrame);

    final result = await db.query(
      'expenses',
      where: 'category_id = ? AND $dateWhere',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );

    return result.map((e) => Expense.fromMap(e)).toList();
  }

  // =====================================================
  // UPDATE EXPENSE
  // =====================================================
  Future<void> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;

    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );

    await _checkBudgetAndNotify(expense);
  }

  // =====================================================
  // DELETE EXPENSE
  // =====================================================
  Future<void> deleteExpense(int id) async {
    final db = await _dbHelper.database;

    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =====================================================
  // CLEAR ALL (DEV ONLY)
  // =====================================================
  Future<void> clearAllExpenses() async {
    final db = await _dbHelper.database;
    await db.delete('expenses');
  }

  // =====================================================
  // DASHBOARD TOTALS
  // =====================================================
  Future<double> getTodayTotal() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE date = ?
      ''',
      [today],
    );

    return (result.first['total'] as num).toDouble();
  }

  Future<double> getThisMonthTotal() async {
    final db = await _dbHelper.database;
    final month = DateTime.now().toIso8601String().substring(0, 7);

    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE substr(date, 1, 7) = ?
      ''',
      [month],
    );

    return (result.first['total'] as num).toDouble();
  }

  // =====================================================
  // 🔐 DATE WHERE CLAUSE BUILDER (LOCAL & SAFE)
  // =====================================================
  String _buildDateWhereClause(AnalyticsTimeFrame? timeFrame) {
    if (timeFrame == null) return '1 = 1';

    final now = DateTime.now();

    switch (timeFrame) {
      case AnalyticsTimeFrame.today:
        return "date = '${_fmt(now)}'";

      case AnalyticsTimeFrame.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return "date = '${_fmt(y)}'";

      case AnalyticsTimeFrame.last7Days:
        final start = now.subtract(const Duration(days: 6));
        return "date BETWEEN '${_fmt(start)}' AND '${_fmt(now)}'";

      case AnalyticsTimeFrame.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return "date BETWEEN '${_fmt(start)}' AND '${_fmt(now)}'";

      case AnalyticsTimeFrame.previousMonth:
        final prev = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0);
        return "date BETWEEN '${_fmt(prev)}' AND '${_fmt(end)}'";

      case AnalyticsTimeFrame.thisYear:
        final start = DateTime(now.year, 1, 1);
        return "date BETWEEN '${_fmt(start)}' AND '${_fmt(now)}'";

      case AnalyticsTimeFrame.previousYear:
        final start = DateTime(now.year - 1, 1, 1);
        final end = DateTime(now.year - 1, 12, 31);
        return "date BETWEEN '${_fmt(start)}' AND '${_fmt(end)}'";
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // =====================================================
  // 🔔 BUDGET CHECK & ALERTS (UNCHANGED)
  // =====================================================
  Future<void> _checkBudgetAndNotify(Expense expense) async {
    try {
      final alertService = AlertService();
      final budgetService = BudgetService();

      final today =
          DateFormat('yyyy-MM-dd').format(DateTime.now());
      final currentMonth =
          DateFormat('yyyy-MM').format(DateTime.now());

      final dailyBudget =
          await budgetService.getOverallBudget(today);
      final dailySpent =
          await budgetService.getOverallSpent(today);

      if (dailyBudget > 0 && dailySpent > dailyBudget) {
        final alreadyTriggered =
            await budgetService.isAlertAlreadyTriggered(
          categoryId: null,
          period: today,
        );

        if (!alreadyTriggered) {
          await alertService.showAlert(
            title: 'Daily Budget Exceeded',
            message: 'You have exceeded your daily spending limit.',
          );

          InAppAlert.show(
            title: 'Daily Budget Exceeded',
            message: 'You have exceeded your daily spending limit.',
          );

          await budgetService.markAlertTriggered(
            categoryId: null,
            period: today,
          );
        }
      }

      final monthlyBudget =
          await budgetService.getOverallBudget(currentMonth);
      final monthlySpent =
          await budgetService.getOverallSpent(currentMonth);

      if (monthlyBudget > 0 && monthlySpent > monthlyBudget) {
        final alreadyTriggered =
            await budgetService.isAlertAlreadyTriggered(
          categoryId: null,
          period: currentMonth,
        );

        if (!alreadyTriggered) {
          await alertService.showAlert(
            title: 'Monthly Budget Exceeded',
            message: 'You have exceeded your monthly spending limit.',
          );

          InAppAlert.show(
            title: 'Monthly Budget Exceeded',
            message: 'You have exceeded your monthly spending limit.',
          );

          await budgetService.markAlertTriggered(
            categoryId: null,
            period: currentMonth,
          );
        }
      }

      final categoryId = expense.categoryId;
      final categoryBudget =
          await budgetService.getCategoryBudget(
        categoryId: categoryId,
        month: currentMonth,
      );
      final categorySpent =
          await budgetService.getCategorySpent(
        categoryId: categoryId,
        month: currentMonth,
      );

      if (categoryBudget > 0 && categorySpent > categoryBudget) {
        final alreadyTriggered =
            await budgetService.isAlertAlreadyTriggered(
          categoryId: categoryId,
          period: currentMonth,
        );

        if (!alreadyTriggered) {
          await alertService.showAlert(
            title: 'Category Budget Exceeded',
            message:
                'You have exceeded the budget for this category.',
          );

          InAppAlert.show(
            title: 'Category Budget Exceeded',
            message:
                'You have exceeded the budget for this category.',
          );

          await budgetService.markAlertTriggered(
            categoryId: categoryId,
            period: currentMonth,
          );
        }
      }
    } catch (e) {
      print('⚠️ Budget alert failed: $e');
    }
  }
}
