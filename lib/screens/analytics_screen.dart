import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/analytics_models.dart';
import '../models/category_model.dart';
import '../services/analytics_service.dart';
import '../services/category_service.dart';
import '../core/enums/analytics_time_frame.dart';
import '../core/utils/safe_padding.dart';
import '../core/theme/system_ui_opacity.dart';
import 'expense_list_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final CategoryService _categoryService = CategoryService();

  AnalyticsTimeFrame _selectedFrame = AnalyticsTimeFrame.thisMonth;

  late Future<List<CategoryAnalytics>> _analyticsFuture;
  late Future<double> _totalSpendFuture;
  late Future<int> _totalTxnFuture;

  Map<int, Category> _categoryMap = {};

  // ✅ SINGLE ACTIVE SLICE
  int _activePieIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    _analyticsFuture =
        _analyticsService.getCategoryAnalytics(timeFrame: _selectedFrame);

    _totalSpendFuture =
        _analyticsService.getTotalSpend(timeFrame: _selectedFrame);

    _totalTxnFuture =
        _analyticsService.getTotalTransactions(timeFrame: _selectedFrame);

    _categoryService.getCategories().then((categories) {
      if (!mounted) return;
      setState(() {
        _categoryMap = {for (final c in categories) c.id!: c};
      });
    });
  }

  Color _pieTextColor(BuildContext context, Color sliceColor) {
    final brightness =
        ThemeData.estimateBrightnessForColor(sliceColor);
    return brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  bool _showSliceText(double percent) => percent >= 3.5;

  void _showAnimatedTimeFramePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 40 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _TimeFrameSheet(
            selected: _selectedFrame,
            onSelect: (frame) {
              Navigator.pop(context);
              setState(() {
                _selectedFrame = frame;
                _activePieIndex = -1; // reset safely
              });
              _loadAnalytics();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: SafePadding.scroll(context),
        child: _buildExpenseDistribution(),
      ),
    );
  }

  Widget _buildExpenseDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TIME FRAME SELECTOR
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showAnimatedTimeFramePicker(context),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceVariant
                  .withOpacity(
                    SystemUiOpacity.resolve(
                      context: context,
                      nearSystemUi: true,
                    ),
                  ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedFrame.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // TOTAL SUMMARY
        FutureBuilder<double>(
          future: _totalSpendFuture,
          builder: (_, spendSnap) {
            return FutureBuilder<int>(
              future: _totalTxnFuture,
              builder: (_, txnSnap) {
                if (!spendSnap.hasData || !txnSnap.hasData) {
                  return const SizedBox.shrink();
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(
                          SystemUiOpacity.resolve(
                            context: context,
                            nearSystemUi: false,
                          ),
                        ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Spend',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹ ${spendSnap.data!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Total Transactions',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              txnSnap.data!.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
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

        // PIE + LEGEND
        FutureBuilder<List<CategoryAnalytics>>(
          future: _analyticsFuture,
          builder: (_, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _analyticsEmptyState();
            }

            final data = snapshot.data!;
            final totalAmount =
                data.fold(0.0, (s, e) => s + e.totalAmount);

            final categoryColors = {
              for (final item in data)
                item.categoryName:
                    Colors.primaries[item.categoryId %
                        Colors.primaries.length]
            };

            return Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 56,
                          sectionsSpace: 3,
                          pieTouchData: PieTouchData(
                            enabled: true,
                            touchCallback: (event, response) {
                              if (event is! FlTapUpEvent ||
                                  response?.touchedSection == null) {
                                return;
                              }

                              setState(() {
                                _activePieIndex = response!
                                    .touchedSection!
                                    .touchedSectionIndex;
                              });
                            },
                          ),
                          sections: List.generate(data.length, (index) {
                            final item = data[index];
                            final percent =
                                (item.totalAmount / totalAmount) * 100;
                            final isActive =
                                index == _activePieIndex;
                            final color =
                                categoryColors[item.categoryName]!;

                            return PieChartSectionData(
                              value: item.totalAmount,
                              color: color,
                              radius: isActive ? 84 : 68,
                              title:
                                  (isActive || _showSliceText(percent))
                                      ? '${percent.toStringAsFixed(1)}%'
                                      : '',
                              titleStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    _pieTextColor(context, color),
                              ),
                            );
                          }),
                        ),
                      ),

                      // 🔹 SAFE CENTER TOOLTIP
                      if (_activePieIndex >= 0 &&
                          _activePieIndex < data.length)
                        _centerTooltip(
                          MapEntry(
                            data[_activePieIndex].categoryName,
                            data[_activePieIndex].totalAmount,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  children: List.generate(data.length, (index) {
                    final item = data[index];
                    final isActive = index == _activePieIndex;
                    final color =
                        categoryColors[item.categoryName]!;

                    return InkWell(
                      key: ValueKey(index), // 🔑 REQUIRED FOR SYNC
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _activePieIndex = index;
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpenseListScreen(
                              categoryId: item.categoryId,
                              categoryName: item.categoryName,
                              timeFrame: _selectedFrame,
                            ),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(8),
                          border: isActive
                              ? Border.all(
                                  color: color, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius:
                                    BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.categoryName} – ₹ ${item.totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _centerTooltip(MapEntry<String, double> entry) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black26,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.key,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹ ${entry.value.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsEmptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Center(child: Text('No spending data')),
    );
  }
}

class _TimeFrameSheet extends StatelessWidget {
  final AnalyticsTimeFrame selected;
  final ValueChanged<AnalyticsTimeFrame> onSelect;

  const _TimeFrameSheet({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AnalyticsTimeFrame.values.map((frame) {
            final isSelected = frame == selected;

            return ListTile(
              title: Text(frame.label),
              trailing:
                  isSelected ? const Icon(Icons.check) : null,
              onTap: () => onSelect(frame),
            );
          }).toList(),
        ),
      ),
    );
  }
}
