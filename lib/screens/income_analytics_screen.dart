import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/income_analytics_service.dart';
import '../core/constants/income_sources.dart';
import 'income_list_screen.dart';

/// ===============================
/// TIME FRAME ENUM
/// ===============================
enum IncomeTimeFrame {
  thisMonth,
  lastMonth,
  thisYear,
}

class IncomeAnalyticsScreen extends StatefulWidget {
  const IncomeAnalyticsScreen({super.key});

  @override
  State<IncomeAnalyticsScreen> createState() =>
      _IncomeAnalyticsScreenState();
}

class _IncomeAnalyticsScreenState
    extends State<IncomeAnalyticsScreen> {
  final IncomeAnalyticsService _service =
      IncomeAnalyticsService();

  late Future<double> _incomeFuture;
  late Future<double> _expenseFuture;
  late Future<double> _savingsFuture;
  late Future<Map<String, double>> _incomeBySourceFuture;

  IncomeTimeFrame _selectedTimeFrame =
      IncomeTimeFrame.thisMonth;

  /// ✅ SINGLE SOURCE OF TRUTH
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _reloadAnalytics();
  }

  // ===============================
  // DATE RANGE RESOLVER
  // ===============================
  DateTimeRange _getDateRange() {
    final now = DateTime.now();

    switch (_selectedTimeFrame) {
      case IncomeTimeFrame.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );

      case IncomeTimeFrame.lastMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        );

      case IncomeTimeFrame.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
    }
  }

  // ===============================
  // SAFE RELOAD
  // ===============================
  void _reloadAnalytics() {
    final range = _getDateRange();

    _incomeFuture =
        _service.getIncomeForRange(range.start, range.end);
    _expenseFuture =
        _service.getExpenseForRange(range.start, range.end);
    _savingsFuture = _loadSavings(range);
    _incomeBySourceFuture =
        _service.getIncomeBySourceForRange(
            range.start, range.end);

    selectedIndex = null;
  }

  Future<double> _loadSavings(DateTimeRange range) async {
    final income =
        await _service.getIncomeForRange(
            range.start, range.end);
    final expense =
        await _service.getExpenseForRange(
            range.start, range.end);
    return income - expense;
  }

  // ===============================
  // TIME FRAME BOTTOM SHEET (VIEW ANALYTICS)
  // ===============================
  void _openTimeFrameSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: IncomeTimeFrame.values.map((frame) {
            final isSelected = frame == _selectedTimeFrame;

            return ListTile(
              title: Text(_timeFrameLabel(frame)),
              trailing: isSelected
                  ? const Icon(Icons.check,
                      color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (frame != _selectedTimeFrame) {
                  setState(() {
                    _selectedTimeFrame = frame;
                    _reloadAnalytics();
                  });
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  String _timeFrameLabel(IncomeTimeFrame frame) {
    switch (frame) {
      case IncomeTimeFrame.thisMonth:
        return 'This Month';
      case IncomeTimeFrame.lastMonth:
        return 'Last Month';
      case IncomeTimeFrame.thisYear:
        return 'This Year';
    }
  }

  // ===============================
  // PIE HELPERS
  // ===============================
  bool shouldShowPercentage({
    required bool isSelected,
    required double percentage,
  }) {
    if (isSelected) return true;
    return percentage >= 2.5;
  }

  Color resolvePercentageTextColor({
    required Color sliceColor,
    required double percentage,
  }) {
    if (percentage < 6) return Colors.black;
    return sliceColor.computeLuminance() < 0.5
        ? Colors.white
        : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Income Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _metricCard(
              title: 'Total Income',
              future: _incomeFuture,
              color: Colors.green,
            ),
            _metricCard(
              title: 'Total Expense',
              future: _expenseFuture,
              color: Colors.redAccent,
            ),
            _metricCard(
              title: 'Savings',
              future: _savingsFuture,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            /// ✅ VIEW ANALYTICS STYLE TIME FRAME ROW
            GestureDetector(
              onTap: _openTimeFrameSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _timeFrameLabel(_selectedTimeFrame),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Income Source Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            /// ===============================
            /// PIE + LEGEND (UNCHANGED)
            /// ===============================
            _buildPieSection(),
          ],
        ),
      ),
    );
  }

  // ===============================
  // PIE SECTION
  // ===============================
  Widget _buildPieSection() {
    return FutureBuilder<Map<String, double>>(
      future: _incomeBySourceFuture,
      builder: (_, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          selectedIndex = null;
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No income data available'),
          );
        }

        final incomeMap = snapshot.data!;
        final sources = incomeMap.keys.toList();
        final values = incomeMap.values.toList();
        final totalIncome =
            values.fold<double>(0, (a, b) => a + b);

        final palette = [
          Colors.green,
          Colors.blue,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.brown,
        ];

        final Map<String, Color> sourceColors = {
          for (int i = 0; i < sources.length; i++)
            sources[i]: palette[i % palette.length]
        };

        return Column(
          children: [
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 48,
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback:
                            (event, response) {
                          if (!event
                              .isInterestedForInteractions) return;
                          if (event is! FlTapUpEvent) return;

                          if (response == null ||
                              response.touchedSection == null ||
                              response.touchedSection!
                                      .touchedSectionIndex ==
                                  -1) {
                            setState(() {
                              selectedIndex = null;
                            });
                            return;
                          }

                          setState(() {
                            selectedIndex = response
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      sections: List.generate(
                        sources.length,
                        (index) {
                          final value = values[index];
                          final percentage =
                              (value / totalIncome) * 100;
                          final isSelected =
                              selectedIndex == index;
                          final color =
                              sourceColors[sources[index]]!;

                          return PieChartSectionData(
                            value: value,
                            color: color,
                            radius:
                                isSelected ? 70 : 60,
                            title: shouldShowPercentage(
                                    isSelected: isSelected,
                                    percentage: percentage)
                                ? '${percentage.toStringAsFixed(1)}%'
                                : '',
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  resolvePercentageTextColor(
                                sliceColor: color,
                                percentage: percentage,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  if (selectedIndex != null)
                    _buildCenterTooltip(
                      context,
                      sources[selectedIndex!],
                      values[selectedIndex!],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildLegend(
              context,
              sources,
              values,
              sourceColors,
            ),
          ],
        );
      },
    );
  }

  // ===============================
  // CENTER TOOLTIP
  // ===============================
  Widget _buildCenterTooltip(
      BuildContext context, String key, double value) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.55)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            IncomeSources.fromKey(key).label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // LEGEND
  // ===============================
  Widget _buildLegend(
    BuildContext context,
    List<String> sources,
    List<double> values,
    Map<String, Color> sourceColors,
  ) {
    return Wrap(
      spacing: 20,
      runSpacing: 12,
      children: List.generate(
        sources.length,
        (index) {
          final key = sources[index];
          final source = IncomeSources.fromKey(key);
          final color = sourceColors[key]!;
          final isActive = selectedIndex == index;

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IncomeListScreen(
                    filterSource: key,
                    title: '${source.label} Income',
                  ),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: color, size: 10),
                  const SizedBox(width: 6),
                  Text(
                    source.label,
                    style: TextStyle(
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '— ₹${values[index].toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===============================
  // METRIC CARD
  // ===============================
  Widget _metricCard({
    required String title,
    required Future<double> future,
    required Color color,
  }) {
    return FutureBuilder<double>(
      future: future,
      builder: (_, snapshot) {
        final value = snapshot.data ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withOpacity(0.12),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₹ ${value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
