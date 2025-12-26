import '../database/db_helper.dart';

class DashboardService {
  final DBHelper _dbHelper = DBHelper();

  /// Today's total spending
  Future<double> getTodayTotal() async {
    final db = await _dbHelper.database;

    final today =
        DateTime.now().toIso8601String().substring(0, 10);

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

  /// Current month total spending
  Future<double> getMonthlyTotal() async {
    final db = await _dbHelper.database;

    final now = DateTime.now();
    final monthStart =
        DateTime(now.year, now.month, 1)
            .toIso8601String()
            .substring(0, 10);

    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE date >= ?
      ''',
      [monthStart],
    );

    return (result.first['total'] as num).toDouble();
  }
}
