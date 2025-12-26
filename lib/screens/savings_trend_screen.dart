import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/income_analytics_service.dart';

// =====================================================
// 🔢 SCALE HELPERS (FINANCE-GRADE)
// =====================================================
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

class SavingsTrendScreen extends StatefulWidget {
  const SavingsTrendScreen({super.key});

  @override
  State<SavingsTrendScreen> createState() => _SavingsTrendScreenState();
}

class _SavingsTrendScreenState extends State<SavingsTrendScreen> {
  final IncomeAnalyticsService _service = IncomeAnalyticsService();

  late Future<List<Map<String, dynamic>>> _trendFuture;

  // =====================================================
  // 🔄 VIEW MODE STATE
  // =====================================================
  bool _isQuarterly = false;

  @override
  void initState() {
    super.initState();
    _trendFuture = _service.getSavingsTrend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Trend')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _trendFuture,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // =====================================================
                // 🔁 MONTHLY / QUARTERLY TOGGLE
                // =====================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 12),

                _legend(),
                const SizedBox(height: 12),

                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6),
                    child: _lineChart(data),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // 📊 QUARTERLY AGGREGATION (LOGIC SAFE)
  // =====================================================
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
        () => {'income': 0, 'expense': 0, 'savings': 0},
      );

      grouped[key]!['income'] =
          grouped[key]!['income']! + m['income'];
      grouped[key]!['expense'] =
          grouped[key]!['expense']! + m['expense'];
      grouped[key]!['savings'] =
          grouped[key]!['savings']! + m['savings'];
    }

    return grouped.entries.map((e) {
      return {
        'period': e.key,
        'income': e.value['income']!,
        'expense': e.value['expense']!,
        'savings': e.value['savings']!,
      };
    }).toList();
  }

  // =====================================================
  // 📈 LINE CHART
  // =====================================================
  Widget _lineChart(List<Map<String, dynamic>> data) {
    final chartData =
        _isQuarterly ? _toQuarterly(data) : data;

    double maxY = 0;
    for (final e in chartData) {
      maxY = [
        maxY,
        e['income'],
        e['expense'],
        e['savings'],
      ].reduce((a, b) => a > b ? a : b);
    }

    final roundedMaxY = _roundUp(maxY);
    final interval = _intervalFor(roundedMaxY);

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    List<FlSpot> savingsSpots = [];

    for (int i = 0; i < chartData.length; i++) {
      incomeSpots.add(
        FlSpot(i.toDouble(), chartData[i]['income']),
      );
      expenseSpots.add(
        FlSpot(i.toDouble(), chartData[i]['expense']),
      );
      savingsSpots.add(
        FlSpot(i.toDouble(), chartData[i]['savings']),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        minY: 0,
        maxY: roundedMaxY,

        gridData: FlGridData(
          show: true,
          horizontalInterval: interval,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.25),
            strokeWidth: 1,
            dashArray: [6, 6],
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
            dashArray: [6, 6],
          ),
        ),

        borderData: FlBorderData(show: false),

        titlesData: FlTitlesData(
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: interval,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '₹${value.toInt()}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 36,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= chartData.length) {
                  return const SizedBox.shrink();
                }

                final label = _isQuarterly
                    ? chartData[index]['period']
                    : DateFormat('MMM').format(
                        DateTime.parse(
                            '${chartData[index]['month']}-01'),
                      );

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),

        clipData: FlClipData.all(),
        lineBarsData: [
          _line(incomeSpots, Colors.green),
          _line(expenseSpots, Colors.redAccent),
          _line(savingsSpots, Colors.blue),
        ],
      ),
    );
  }

  // =====================================================
  // 🎨 LINE STYLE
  // =====================================================
  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.4,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.06),
      ),
    );
  }

  // =====================================================
  // LEGEND
  // =====================================================
  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _LegendItem(color: Colors.green, label: 'Income'),
        _LegendItem(color: Colors.redAccent, label: 'Expense'),
        _LegendItem(color: Colors.blue, label: 'Savings'),
      ],
    );
  }
}

// =====================================================
// LEGEND ITEM
// =====================================================
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
