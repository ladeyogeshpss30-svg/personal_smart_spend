// ===============================
// CATEGORY-WISE ANALYTICS (PIE)
// ===============================
class CategoryAnalytics {
  final int categoryId;
  final String categoryName;
  final double totalAmount;

  CategoryAnalytics({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
  });
}

// ===============================
// MONTHLY ANALYTICS (LEGACY / SAFE)
// ===============================
class MonthlyAnalytics {
  final String month; // YYYY-MM
  final double totalAmount;

  MonthlyAnalytics({
    required this.month,
    required this.totalAmount,
  });
}
