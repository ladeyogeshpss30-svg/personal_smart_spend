import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../core/theme/system_ui_opacity.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final IncomeService _incomeService = IncomeService();

  late Future<double> _todayExpenseFuture;
  late Future<double> _monthExpenseFuture;
  late Future<double> _monthIncomeFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    _todayExpenseFuture = _expenseService.getTodayTotal();
    _monthExpenseFuture = _expenseService.getThisMonthTotal();
    _monthIncomeFuture = _incomeService.getThisMonthIncome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadDashboard();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===============================
            // GREETING
            // ===============================
            const Text(
              'Hello, Yogesh 👋',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // ===============================
            // HERO SUMMARY CARDS
            // ===============================
            _heroExpenseCard(
              title: 'Today',
              subtitle: 'Total Expense',
              icon: Icons.today,
              gradient: const [
                Color(0xFFEAF4FF),
                Color(0xFFD6E9FF),
              ],
              expenseFuture: _todayExpenseFuture,
            ),

            const SizedBox(height: 14),

            _heroExpenseCard(
              title: 'This Month',
              subtitle: 'Total Expense',
              icon: Icons.calendar_month,
              gradient: const [
                Color(0xFFFFF4E5),
                Color(0xFFFFE6C7),
              ],
              expenseFuture: _monthExpenseFuture,
            ),

            const SizedBox(height: 14),

            // ===============================
            // SAVINGS CARD (MONTHLY)
            // ===============================
            FutureBuilder<double>(
              future: _monthIncomeFuture,
              builder: (_, incomeSnap) {
                final income = incomeSnap.data ?? 0.0;

                return FutureBuilder<double>(
                  future: _monthExpenseFuture,
                  builder: (_, expenseSnap) {
                    final expense = expenseSnap.data ?? 0.0;
                    final savings = income - expense;

                    final bool isPositive = savings >= 0;
                    final Color valueColor =
                        isPositive ? Colors.green : Colors.redAccent;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: isPositive
                              ? const [
                                  Color(0xFFE6F4EA),
                                  Color(0xFFD1FADF),
                                ]
                              : const [
                                  Color(0xFFFFEBEE),
                                  Color(0xFFFFCDD2),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                Colors.white.withOpacity(0.85),
                            child: Icon(
                              isPositive
                                  ? Icons.savings_outlined
                                  : Icons.warning_amber_rounded,
                              size: 26,
                              color: valueColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'This Month',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Savings',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹ ${savings.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: valueColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 28),

            // ===============================
            // ACTIONS
            // ===============================
            _dashboardAction(
              icon: Icons.add_circle_outline,
              label: 'Add Income',
              onTap: () async {
                await Navigator.pushNamed(context, '/add-income');
                _loadDashboard();
                setState(() {});
              },
            ),

            _dashboardAction(
              icon: Icons.trending_up,
              label: 'Income Analytics',
              onTap: () =>
                  Navigator.pushNamed(context, '/income-analytics'),
            ),

            _dashboardAction(
              icon: Icons.show_chart,
              label: 'Savings Trend',
              onTap: () =>
                  Navigator.pushNamed(context, '/savings-trend'),
            ),

            // ✅ NEW DASHBOARD BUTTON
            _dashboardAction(
              icon: Icons.bar_chart,
              label: 'Income vs Expense',
              onTap: () =>
                  Navigator.pushNamed(context, '/income-vs-expense'),
            ),

            _dashboardAction(
              icon: Icons.list_alt,
              label: 'View Expenses',
              onTap: () async {
                await Navigator.pushNamed(context, '/expenses');
                _loadDashboard();
                setState(() {});
              },
            ),

            _dashboardAction(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Manage Budgets',
              onTap: () =>
                  Navigator.pushNamed(context, '/budgets'),
            ),

            _dashboardAction(
              icon: Icons.analytics_outlined,
              label: 'View Analytics',
              onTap: () =>
                  Navigator.pushNamed(context, '/analytics'),
            ),

            _dashboardAction(
              icon: Icons.picture_as_pdf_outlined,
              label: 'View Reports',
              onTap: () =>
                  Navigator.pushNamed(context, '/reports'),
            ),

            _dashboardAction(
              icon: Icons.category_outlined,
              label: 'Custom Categories',
              onTap: () =>
                  Navigator.pushNamed(context, '/categories'),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 🌟 HERO EXPENSE CARD
  // =====================================================
  Widget _heroExpenseCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Future<double> expenseFuture,
  }) {
    return FutureBuilder<double>(
      future: expenseFuture,
      builder: (_, snapshot) {
        final value = snapshot.data ?? 0.0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.85),
                child: Icon(
                  icon,
                  size: 26,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹ ',
                      ).format(value),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // 🚀 DASHBOARD ACTION BUTTON
  // =====================================================
  Widget _dashboardAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
