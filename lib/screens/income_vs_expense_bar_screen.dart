import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/income_analytics_service.dart';

class IncomeVsExpenseBarScreen extends StatefulWidget {
  const IncomeVsExpenseBarScreen({super.key});

  @override
  State<IncomeVsExpenseBarScreen> createState() =>
      _IncomeVsExpenseBarScreenState();
}

class _IncomeVsExpenseBarScreenState
    extends State<IncomeVsExpenseBarScreen> {
  final IncomeAnalyticsService _service =
      IncomeAnalyticsService();

  late Future<List<Map<String, dynamic>>> _future;
  bool _isQuarterly = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getSavingsTrend();
  }

  // ===============================
  // SCALE HELPERS (AUTO ADJUST)
  // ===============================
  double _roundUp(double value) {
    if (value <= 10000) return 10000;
    if (value <= 25000) return 25000;
    if (value <= 50000) return 50000;
    if (value <= 100000) return 100000;
    if (value <= 250000) return 250000;
    if (value <= 500000) return 500000;
    return ((value / 100000).ceil()) * 100000;
  }

  double _intervalFor(double max) {
    if (max <= 10000) return 2000;
    if (max <= 25000) return 5000;
    if (max <= 50000) return 10000;
    if (max <= 100000) return 20000;
    if (max <= 250000) return 50000;
    return 100000;
  }

  // ===============================
  // QUARTERLY GROUPING
  // ===============================
  List<Map<String, dynamic>> _toQuarterly(
    List<Map<String, dynamic>> monthly,
  ) {
    final Map<String, Map<String, double>> grouped = {};

    for (final m in monthly) {
      final date = DateTime.parse('${m['month']}-01');
      final q = ((date.month - 1) ~/ 3) + 1;
      final key = '${date.year}-Q$q';

      grouped.putIfAbsent(
        key,
        () => {'income': 0, 'expense': 0},
      );

      grouped[key]!['income'] =
          grouped[key]!['income']! + m['income'];
      grouped[key]!['expense'] =
          grouped[key]!['expense']! + m['expense'];
    }

    return grouped.entries.map((e) {
      return {
        'period': e.key,
        'income': e.value['income']!,
        'expense': e.value['expense']!,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Income vs Expense')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final raw = snapshot.data!;
          final data =
              _isQuarterly ? _toQuarterly(raw) : raw;

          double maxY = 0;
          for (final e in data) {
            maxY = [
              maxY,
              e['income'],
              e['expense'],
            ].reduce((a, b) => a > b ? a : b);
          }

          final roundedMaxY = _roundUp(maxY);
          final interval = _intervalFor(roundedMaxY);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ===============================
                // TOGGLE
                // ===============================
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Monthly'),
                      selected: !_isQuarterly,
                      onSelected: (_) =>
                          setState(() => _isQuarterly = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Quarterly'),
                      selected: _isQuarterly,
                      onSelected: (_) =>
                          setState(() => _isQuarterly = true),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _legend(),

                const SizedBox(height: 12),

                Expanded(
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: roundedMaxY,
                      barTouchData:
                          BarTouchData(enabled: true),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine:
                            (value) => FlLine(
                          color: Colors.grey
                              .withOpacity(0.25),
                          strokeWidth: 1,
                          dashArray: [6, 6],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 56,
                            interval: interval,
                            getTitlesWidget:
                                (value, _) => Padding(
                              padding:
                                  const EdgeInsets.only(right: 8),
                              child: Text(
                                '₹${value.toInt()}',
                                style: const TextStyle(
                                    fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 36,
                            getTitlesWidget:
                                (value, _) {
                              final index = value.toInt();
                              if (index < 0 ||
                                  index >= data.length) {
                                return const SizedBox.shrink();
                              }

                              final label = _isQuarterly
                                  ? data[index]['period']
                                  : DateFormat('MMM').format(
                                      DateTime.parse(
                                          '${data[index]['month']}-01'),
                                    );

                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: 8),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                      fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups:
                          _buildBars(data),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===============================
  // BAR GROUPS
  // ===============================
  List<BarChartGroupData> _buildBars(
    List<Map<String, dynamic>> data,
  ) {
    return List.generate(data.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: data[i]['income'],
            width: 8,
            borderRadius: BorderRadius.circular(4),
            color: Colors.green,
          ),
          BarChartRodData(
            toY: data[i]['expense'],
            width: 8,
            borderRadius: BorderRadius.circular(4),
            color: Colors.redAccent,
          ),
        ],
      );
    });
  }

  // ===============================
  // LEGEND
  // ===============================
  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _Legend(color: Colors.green, text: 'Income'),
        SizedBox(width: 16),
        _Legend(color: Colors.redAccent, text: 'Expense'),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
