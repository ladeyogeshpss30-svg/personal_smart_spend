import '../database/db_helper.dart';

class IncomeAnalyticsService {
  final DBHelper _dbHelper = DBHelper();

  // ===============================
  // TOTAL INCOME (MONTH)
  // ===============================
  Future<double> getMonthlyIncome(String month) async {
    final db = await _dbHelper.database;

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

  // ===============================
  // TOTAL EXPENSE (MONTH)
  // ===============================
  Future<double> getMonthlyExpense(String month) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount),0) AS total
      FROM expenses
      WHERE substr(date,1,7) = ?
      ''',
      [month],
    );

    return (result.first['total'] as num).toDouble();
  }

  // ===============================
  // SAVINGS (MONTH)
  // ===============================
  Future<double> getMonthlySavings(String month) async {
    final income = await getMonthlyIncome(month);
    final expense = await getMonthlyExpense(month);
    return income - expense;
  }

  // ===============================
  // MONTHLY TREND (12 MONTHS)
  // ===============================
  Future<List<Map<String, dynamic>>> getSavingsTrend() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final List<Map<String, dynamic>> trend = [];

    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final month =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';

      final income = await getMonthlyIncome(month);
      final expense = await getMonthlyExpense(month);

      trend.add({
        'month': month,
        'income': income,
        'expense': expense,
        'savings': income - expense,
      });
    }

    return trend.reversed.toList();
  }

  // ===============================
  // INCOME BY SOURCE (MONTH)
  // ===============================
  Future<Map<String, double>> getIncomeBySourceForMonth(
    String month,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT source, IFNULL(SUM(amount),0) AS total
      FROM income
      WHERE substr(date,1,7) = ?
      GROUP BY source
      ''',
      [month],
    );

    return {
      for (final row in result)
        row['source'] as String:
            (row['total'] as num).toDouble()
    };
  }

  // =====================================================
  // ✅ NEW: TOTAL INCOME (DATE RANGE)
  // =====================================================
  Future<double> getIncomeForRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM income
      WHERE date BETWEEN ? AND ?
      ''',
      [
        from.toIso8601String(),
        to.toIso8601String(),
      ],
    );

    return (result.first['total'] as num).toDouble();
  }

  // =====================================================
  // ✅ NEW: INCOME BY SOURCE (DATE RANGE)
  // =====================================================
  Future<Map<String, double>> getIncomeBySourceForRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT source, SUM(amount) AS total
      FROM income
      WHERE date BETWEEN ? AND ?
      GROUP BY source
      ''',
      [
        from.toIso8601String(),
        to.toIso8601String(),
      ],
    );

    final Map<String, double> map = {};
    for (final row in result) {
      map[row['source'] as String] =
          (row['total'] as num).toDouble();
    }

    return map;
  }

  // =====================================================
  // ✅ NEW: TOTAL EXPENSE (DATE RANGE)
  // =====================================================
  Future<double> getExpenseForRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE date BETWEEN ? AND ?
      ''',
      [
        from.toIso8601String(),
        to.toIso8601String(),
      ],
    );

    return (result.first['total'] as num).toDouble();
  }
}
