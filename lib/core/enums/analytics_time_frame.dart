enum AnalyticsTimeFrame {
  today,
  yesterday,
  last7Days,
  thisMonth,
  previousMonth,
  thisYear,
  previousYear,
}

extension AnalyticsTimeFrameLabel on AnalyticsTimeFrame {
  String get label {
    switch (this) {
      case AnalyticsTimeFrame.today:
        return 'Today';
      case AnalyticsTimeFrame.yesterday:
        return 'Yesterday';
      case AnalyticsTimeFrame.last7Days:
        return 'Last 7 Days';
      case AnalyticsTimeFrame.thisMonth:
        return 'This Month';
      case AnalyticsTimeFrame.previousMonth:
        return 'Previous Month';
      case AnalyticsTimeFrame.thisYear:
        return 'This Year';
      case AnalyticsTimeFrame.previousYear:
        return 'Previous Year';
    }
  }
}
