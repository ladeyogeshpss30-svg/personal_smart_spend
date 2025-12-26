import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';
import '../core/utils/safe_padding.dart';
import '../core/enums/analytics_time_frame.dart';
import 'edit_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  final AnalyticsTimeFrame? timeFrame;

  const ExpenseListScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.timeFrame,
  });

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final CategoryService _categoryService = CategoryService();

  final Map<int, Category> _categoryMap = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _categoryService.insertDefaultCategoriesIfNeeded();

    final categories = await _categoryService.getCategories();
    for (final c in categories) {
      if (c.id != null) {
        _categoryMap[c.id!] = c;
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  // ===============================
  // DATE HELPERS
  // ===============================
  bool _isToday(String date) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return date == today;
  }

  double _getDayTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  // ===============================
  // DELETE WITH UNDO
  // ===============================
  Future<void> _deleteExpenseWithUndo(
    BuildContext context,
    Expense expense,
  ) async {
    await _expenseService.deleteExpense(expense.id!);
    setState(() {});

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Expense deleted'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await _expenseService.addExpense(expense);
            setState(() {});
          },
        ),
      ),
    );
  }

  // ===============================
  // NAVIGATION
  // ===============================
  Future<void> _openAddExpenseScreen() async {
    await Navigator.pushNamed(context, '/add-expense');
    setState(() {});
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Expenses'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseScreen,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Expense>>(
        future: widget.categoryId == null
            ? _expenseService.getExpensesByTimeFrame(widget.timeFrame)
            : _expenseService.getExpensesByCategoryId(
                widget.categoryId!,
                widget.timeFrame,
              ),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;

          if (expenses.isEmpty) {
            return _EmptyExpenseState(onAdd: _openAddExpenseScreen);
          }

          // GROUP BY DATE
          final Map<String, List<Expense>> groupedExpenses = {};
          for (final e in expenses) {
            groupedExpenses.putIfAbsent(e.date, () => []).add(e);
          }

          final sortedDates = groupedExpenses.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: SafePadding.scroll(context),
            itemCount: sortedDates.length,
            itemBuilder: (_, index) {
              final dateKey = sortedDates[index];
              final dayExpenses = groupedExpenses[dateKey]!;

              final isToday = _isToday(dateKey);
              final dayTotal = _getDayTotal(dayExpenses);
              final formattedDate =
                  DateFormat('dd MMMM yyyy').format(DateTime.parse(dateKey));

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DATE HEADER
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday ? 'Today' : formattedDate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹ ${dayTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // EXPENSE ROWS
                    ...dayExpenses.map((e) {
                      final category = _categoryMap[e.categoryId];

                      return InkWell(
                        onTap: () => _showExpenseActions(context, e),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      category?.color ?? Colors.grey.value,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '₹ ${e.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category?.name ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (e.note != null &&
                                          e.note!.isNotEmpty)
                                        Text(
                                          e.note!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showExpenseActions(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Expense'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditExpenseScreen(expense: expense),
                  ),
                );
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Expense'),
              onTap: () async {
                Navigator.pop(context);
                await _deleteExpenseWithUndo(context, expense);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// EMPTY STATE
// =====================================================
class _EmptyExpenseState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyExpenseState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No expenses found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }
}
