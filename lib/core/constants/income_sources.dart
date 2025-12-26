import 'package:flutter/material.dart';

class IncomeSources {
  static const List<IncomeSourceItem> items = [
    IncomeSourceItem(
      key: 'salary',
      label: 'Salary',
      icon: Icons.work_outline,
    ),
    IncomeSourceItem(
      key: 'business',
      label: 'Business',
      icon: Icons.storefront_outlined,
    ),
    IncomeSourceItem(
      key: 'freelance',
      label: 'Freelance',
      icon: Icons.laptop_mac_outlined,
    ),
    IncomeSourceItem(
      key: 'investment',
      label: 'Investment',
      icon: Icons.trending_up,
    ),
    IncomeSourceItem(
      key: 'rental',
      label: 'Rental',
      icon: Icons.home_work_outlined,
    ),
    IncomeSourceItem(
      key: 'other',
      label: 'Other',
      icon: Icons.more_horiz,
    ),
  ];

  static IncomeSourceItem fromKey(String key) {
    return items.firstWhere(
      (e) => e.key == key,
      orElse: () => items.last,
    );
  }
}

class IncomeSourceItem {
  final String key;   // stored in DB
  final String label; // UI text
  final IconData icon;

  const IncomeSourceItem({
    required this.key,
    required this.label,
    required this.icon,
  });
}
