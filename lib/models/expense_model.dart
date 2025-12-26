class Expense {
  final int? id;
  final double amount;
  final int categoryId;
  final String date;
  final String? note;

  Expense({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
  });

  /// Convert Expense object to DB-compatible map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId, // ✅ MUST be snake_case
      'date': date,              // ✅ Stored as TEXT
      'note': note,
    };
  }

  /// Create Expense object from DB row
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      date: map['date'] as String,
      note: map['note'] as String?,
    );
  }
}
