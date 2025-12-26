import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';
import '../services/budget_service.dart';
import '../core/utils/category_icon_mapper.dart';
import '../core/constants/category_icons.dart'; // ✅ REQUIRED IMPORT

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  final CategoryService _categoryService = CategoryService();
  final BudgetService _budgetService = BudgetService();

  late Future<List<Category>> _categoriesFuture;
  final String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _categoryService.getAllCategories();
  }

  // =====================================================
  // ✅ SINGLE SOURCE OF TRUTH FOR CATEGORY COLOR
  // =====================================================
  Color _resolveCategoryColor(Category category) {
    // 1️⃣ Use DB color (now always ARGB)
    if (category.color != 0) {
      return Color(category.color);
    }

    // 2️⃣ Fallback → icon-based color (custom category match)
    final IconData iconData =
        CategoryIconMapper.getIcon(category.icon);

    return CategoryIcons.colorForIcon(iconData);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade600,
        elevation: 0,
        title: const Text(
          'Budgets',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
              child: Text(
                'Overall Budgets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverallCard(
                  title: 'Daily Budget',
                  period: today,
                  icon: Icons.today_rounded,
                  iconColor: Colors.teal.shade600,
                ),
                const SizedBox(height: 12),
                _buildOverallCard(
                  title: 'Monthly Budget',
                  period: _currentMonth,
                  icon: Icons.calendar_month_rounded,
                  iconColor: Colors.teal.shade700,
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 36, 18, 16),
              child: Text(
                'Category Budgets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ),
          ),

          FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCategoryCard(snapshot.data![index]),
                      );
                    },
                    childCount: snapshot.data!.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard({
    required String title,
    required String period,
    required IconData icon,
    required Color iconColor,
  }) {
    return FutureBuilder<double>(
      future: _budgetService.getOverallBudget(period),
      builder: (_, budgetSnap) {
        final budget = budgetSnap.data ?? 0.0;

        return FutureBuilder<double>(
          future: _budgetService.getOverallSpent(period),
          builder: (_, spentSnap) {
            final spent = spentSnap.data ?? 0.0;
            final progress =
                budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

            return _SimplePremiumCard(
              title: title,
              icon: icon,
              iconColor: iconColor,
              spent: spent,
              budget: budget,
              progress: progress,
              progressColor: iconColor,
              onEdit: () => _showStyledDialog(
                title: 'Set $title',
                isOverall: true,
                period: period,
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // ✅ CATEGORY CARD (COLOR FIX APPLIED)
  // =====================================================
  Widget _buildCategoryCard(Category category) {
    final Color baseColor = _resolveCategoryColor(category);

    return FutureBuilder<double>(
      future: _budgetService.getCategoryBudget(
        categoryId: category.id!,
        month: _currentMonth,
      ),
      builder: (_, budgetSnap) {
        final budget = budgetSnap.data ?? 0.0;

        return FutureBuilder<double>(
          future: _budgetService.getCategorySpent(
            categoryId: category.id!,
            month: _currentMonth,
          ),
          builder: (_, spentSnap) {
            final spent = spentSnap.data ?? 0.0;
            final progress =
                budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

            return _SimplePremiumCard(
              title: category.name,
              icon: CategoryIconMapper.getIcon(category.icon),
              iconColor: baseColor,
              spent: spent,
              budget: budget,
              progress: progress,
              progressColor: baseColor,
              onEdit: () => _showStyledDialog(
                title: 'Set Budget for ${category.name}',
                category: category,
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // DIALOG (UNCHANGED)
  // =====================================================
  void _showStyledDialog({
    required String title,
    Category? category,
    String? period,
    bool isOverall = false,
  }) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter amount'),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (isOverall) {
                      await _budgetService.resetOverallBudget(period!);
                    } else {
                      await _budgetService.resetCategoryBudget(
                        categoryId: category!.id!,
                        month: _currentMonth,
                      );
                    }
                    setState(() {});
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(controller.text.trim());
                    if (amount == null || amount <= 0) return;

                    Navigator.pop(context);
                    if (isOverall) {
                      await _budgetService.setOverallBudget(
                        period: period!,
                        amount: amount,
                      );
                    } else {
                      await _budgetService.setCategoryBudget(
                        categoryId: category!.id!,
                        month: _currentMonth,
                        amount: amount,
                      );
                    }
                    setState(() {});
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// UI CARD (UNCHANGED)
// =====================================================
class _SimplePremiumCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color progressColor;
  final double spent;
  final double budget;
  final double progress;
  final VoidCallback onEdit;

  const _SimplePremiumCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.progressColor,
    required this.spent,
    required this.budget,
    required this.progress,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor,
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${spent.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}
