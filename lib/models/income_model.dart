class Income {
  final int? id;
  final double amount;
  final String source;
  final String date; // yyyy-MM-dd
  final String? note;

  Income({
    this.id,
    required this.amount,
    required this.source,
    required this.date,
    this.note,
  });

  /// Convert model to DB map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'source': source,
      'date': date,
      'note': note,
    };
  }

  /// Create model from DB map
  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      source: map['source'] as String,
      date: map['date'] as String,
      note: map['note'] as String?,
    );
  }

  /// Optional: copyWith for safe editing (recommended)
  Income copyWith({
    int? id,
    double? amount,
    String? source,
    String? date,
    String? note,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
