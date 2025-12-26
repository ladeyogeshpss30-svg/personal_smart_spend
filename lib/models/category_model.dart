class Category {
  final int? id;
  final String name;
  final int color; // ALWAYS ARGB (non-transparent)
  final bool isSystem;
  final String? icon;

  Category({
    this.id,
    required this.name,
    required this.color,
    required this.isSystem,
    this.icon,
  });

  // ===============================
  // FROM DB → MODEL (PERMANENT FIX)
  // ===============================
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] is int ? map['id'] as int : null,
      name: (map['name'] ?? '').toString(),
      color: _parseColor(map['color']), // 🔑 CORE FIX
      isSystem: map['is_system'] == 1,
      icon: map['icon']?.toString(),
    );
  }

  // ===============================
  // MODEL → DB
  // ===============================
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'is_system': isSystem ? 1 : 0,
    };
  }

  // ===============================
  // ✅ FINAL COLOR PARSER
  // Handles:
  // int, "int", "#009688", "0xFF009688"
  // ===============================
  static int _parseColor(dynamic value) {
    if (value == null) return 0;

    // Already int
    if (value is int) {
      return _ensureAlpha(value);
    }

    if (value is String) {
      String v = value.trim().toLowerCase();

      // "#009688"
      if (v.startsWith('#')) {
        v = v.replaceFirst('#', '');
        return _ensureAlpha(int.parse(v, radix: 16));
      }

      // "0xff009688"
      if (v.startsWith('0x')) {
        return _ensureAlpha(int.parse(v));
      }

      // Plain integer string
      final parsed = int.tryParse(v);
      if (parsed != null) {
        return _ensureAlpha(parsed);
      }
    }

    return 0;
  }

  // ===============================
  // 🔒 FORCE ALPHA CHANNEL (NO TRANSPARENT COLORS)
  // ===============================
  static int _ensureAlpha(int color) {
    return (color & 0xFF000000) == 0
        ? 0xFF000000 | color
        : color;
  }
}
