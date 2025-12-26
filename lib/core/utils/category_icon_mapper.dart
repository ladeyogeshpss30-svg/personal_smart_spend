import 'package:flutter/material.dart';

class CategoryIconMapper {
  // =====================================================
  // ICON RESOLVER
  // =====================================================
  static IconData getIcon(String? icon) {
    if (icon == null || icon.isEmpty) {
      return Icons.category;
    }

    // ✅ CASE 1: Numeric icon codePoint (Custom Categories)
    final int? codePoint = int.tryParse(icon);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    // ✅ CASE 2: System category string keys
    switch (icon) {
      case 'food':
        return Icons.restaurant;
      case 'bills':
        return Icons.receipt_long;
      case 'transport':
        return Icons.directions_bus;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      case 'invest':
        return Icons.trending_up;
      case 'lending':
        return Icons.volunteer_activism;
      case 'unknown':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  // =====================================================
  // COLOR RESOLVER ✅ (NEW — DO NOT REMOVE)
  // =====================================================
  static Color getColor(String? icon) {
    switch (icon) {
      case 'transport':
        return Colors.green;
      case 'food':
        return Colors.orange;
      case 'shopping':
        return Colors.blue;
      case 'health':
        return Colors.teal;
      case 'entertainment':
        return Colors.redAccent;
      case 'bills':
        return Colors.indigo;
      case 'invest':
        return Colors.purple;
      case 'lending':
        return Colors.brown;
      case 'unknown':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
