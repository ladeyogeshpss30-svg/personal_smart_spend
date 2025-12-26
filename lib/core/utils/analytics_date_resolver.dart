import '../enums/analytics_time_frame.dart';

class AnalyticsDateRange {
  final String fromDate;
  final String toDate;

  AnalyticsDateRange(this.fromDate, this.toDate);
}

class AnalyticsDateResolver {
  static AnalyticsDateRange resolve(AnalyticsTimeFrame frame) {
    final now = DateTime.now();

    late DateTime from;
    late DateTime to;

    switch (frame) {
      case AnalyticsTimeFrame.today:
        from = DateTime(now.year, now.month, now.day);
        to = now;
        break;

      case AnalyticsTimeFrame.yesterday:
        final y = now.subtract(const Duration(days: 1));
        from = DateTime(y.year, y.month, y.day);
        to = DateTime(y.year, y.month, y.day, 23, 59, 59);
        break;

      case AnalyticsTimeFrame.last7Days:
        from = now.subtract(const Duration(days: 6));
        to = now;
        break;

      case AnalyticsTimeFrame.thisMonth:
        from = DateTime(now.year, now.month, 1);
        to = now;
        break;

      case AnalyticsTimeFrame.previousMonth:
        final prev = DateTime(now.year, now.month - 1, 1);
        from = prev;
        to = DateTime(prev.year, prev.month + 1, 0, 23, 59, 59);
        break;

      case AnalyticsTimeFrame.thisYear:
        from = DateTime(now.year, 1, 1);
        to = now;
        break;

      case AnalyticsTimeFrame.previousYear:
        from = DateTime(now.year - 1, 1, 1);
        to = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
    }

    return AnalyticsDateRange(
      _format(from),
      _format(to),
    );
  }

  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
