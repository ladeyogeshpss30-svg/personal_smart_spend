enum ReportType {
  daily,
  monthly,
  yearly,
}

extension ReportTypeX on ReportType {
  String get label {
    switch (this) {
      case ReportType.daily:
        return 'Daily Report';
      case ReportType.monthly:
        return 'Monthly Report';
      case ReportType.yearly:
        return 'Yearly Report';
    }
  }
}
