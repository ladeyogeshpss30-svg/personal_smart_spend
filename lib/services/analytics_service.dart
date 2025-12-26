import '../database/db_helper.dart';
import '../models/analytics_models.dart';
import '../core/enums/analytics_time_frame.dart';
import '../core/utils/analytics_date_resolver.dart';

class AnalyticsService {
  final DBHelper _dbHelper = DBHelper();

  // =========================================================
  // ✅ TOTAL SPEND BY TIME FRAME
  // =========================================================
  Future<double> getTotalSpend({
    required AnalyticsTimeFrame timeFrame,
  }) async {
    final range = AnalyticsDateResolver.resolve(timeFrame);
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT IFNULL(SUM(amount), 0) AS total
      FROM expenses
      WHERE date BETWEEN ? AND ?
      ''',
      [range.fromDate, range.toDate],
    );

    return (result.first['total'] as num).toDouble();
  }

  // =========================================================
  // ✅ TOTAL TRANSACTIONS COUNT (NEW – REQUIRED)
  // =========================================================
  Future<int> getTotalTransactions({
    required AnalyticsTimeFrame timeFrame,
  }) async {
    final range = AnalyticsDateResolver.resolve(timeFrame);
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt
      FROM expenses
      WHERE date BETWEEN ? AND ?
      ''',
      [range.fromDate, range.toDate],
    );

    return (result.first['cnt'] as num).toInt();
  }

  // =========================================================
  // ✅ CATEGORY ANALYTICS (PIE CHART ONLY)
  // =========================================================
  Future<List<CategoryAnalytics>> getCategoryAnalytics({
    required AnalyticsTimeFrame timeFrame,
  }) async {
    final range = AnalyticsDateResolver.resolve(timeFrame);
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        c.id AS category_id,
        c.name AS category_name,
        IFNULL(SUM(e.amount), 0) AS total
      FROM expenses e
      JOIN categories c ON c.id = e.category_id
      WHERE e.date BETWEEN ? AND ?
      GROUP BY c.id, c.name
      ORDER BY total DESC
      LIMIT 13
      ''',
      [range.fromDate, range.toDate],
    );

    return result.map((row) {
      return CategoryAnalytics(
        categoryId: row['category_id'] as int,
        categoryName: row['category_name'] as String,
        totalAmount: (row['total'] as num).toDouble(),
      );
    }).toList();
  }

  // =========================================================
  // 🆕 TRANSACTIONS BETWEEN DATES (REPORT PREVIEW)
  // =========================================================
  Future<List<Map<String, dynamic>>> getTransactionsBetweenDates({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _dbHelper.database;

    final fromDate = from.toIso8601String();
    final toDate = to.toIso8601String();

    return await db.rawQuery(
      '''
      SELECT 
        e.date,
        e.amount,
        e.note,
        c.id AS category_id,
        c.name AS category_name,
        c.icon,
        c.color
      FROM expenses e
      JOIN categories c ON c.id = e.category_id
      WHERE date(e.date) BETWEEN date(?) AND date(?)
      ORDER BY date(e.date) ASC
      ''',
      [fromDate, toDate],
    );
  }

  // =========================================================
  // CATEGORY-WISE TOTAL (LEGACY / SUPPORT)
  // =========================================================
  Future<List<CategoryAnalytics>> getCategoryWiseTotal({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        c.id AS category_id,
        c.name AS category_name,
        IFNULL(SUM(e.amount), 0) AS total
      FROM expenses e
      JOIN categories c ON c.id = e.category_id
      WHERE e.date BETWEEN ? AND ?
      GROUP BY c.id, c.name
      ORDER BY total DESC
      ''',
      [fromDate, toDate],
    );

    return result.map((row) {
      return CategoryAnalytics(
        categoryId: row['category_id'] as int,
        categoryName: row['category_name'] as String,
        totalAmount: (row['total'] as num).toDouble(),
      );
    }).toList();
  }

  // =========================================================
  // TRANSACTIONS BY CATEGORY (PIE CHART DRILL-DOWN)
  // =========================================================
  Future<List<Map<String, dynamic>>> getTransactionsByCategory({
    required int categoryId,
    required String fromDate,
    required String toDate,
  }) async {
    final db = await _dbHelper.database;

    return await db.query(
      'expenses',
      where: 'category_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [categoryId, fromDate, toDate],
      orderBy: 'date DESC',
    );
  }

  // =========================================================
  // TRANSACTIONS BY MONTH (SUPPORT)
  // =========================================================
  Future<List<Map<String, dynamic>>> getTransactionsByMonth({
    required String month, // yyyy-MM
  }) async {
    final db = await _dbHelper.database;

    return await db.query(
      'expenses',
      where: 'substr(date,1,7) = ?',
      whereArgs: [month],
      orderBy: 'date DESC',
    );
  }
}
