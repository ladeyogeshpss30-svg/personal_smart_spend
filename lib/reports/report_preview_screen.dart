import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/analytics_service.dart';
import '../services/report_pdf_service.dart';
import '../core/utils/safe_padding.dart';
import '../core/theme/system_ui_opacity.dart'; // ✅ NEW (MANDATORY)

class ReportPreviewScreen extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;

  const ReportPreviewScreen({
    super.key,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<ReportPreviewScreen> createState() =>
      _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  late DateTime _fromDate;
  late DateTime _toDate;

  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;

    _transactionsFuture =
        _analyticsService.getTransactionsBetweenDates(
      from: _fromDate,
      to: _toDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Preview'),
      ),

      // ✅ ALWAYS VISIBLE DOWNLOAD BUTTON
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Download PDF'),
            onPressed: () async {
              final data = await _transactionsFuture;

              final file =
                  await ReportPdfService.generateDateRangeReport(
                from: _fromDate,
                to: _toDate,
                transactions: data,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF saved at ${file.path}'),
                ),
              );
            },
          ),
        ),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactionsFuture,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions found'));
          }

          double totalAmount = 0;
          final Map<String, double> categoryTotals = {};

          for (final t in transactions) {
            final amount = (t['amount'] as num).toDouble();
            totalAmount += amount;

            categoryTotals[t['category_name']] =
                (categoryTotals[t['category_name']] ?? 0) + amount;
          }

          return ListView(
            // ✅ GLOBAL SYSTEM-SAFE SCROLL
            padding: SafePadding.scroll(context),
            children: [
              // ===============================
              // HEADER
              // ===============================
              Text(
                'Personal Smart Spend',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'From ${format.format(_fromDate)} to ${format.format(_toDate)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 16),

              // ===============================
              // SUMMARY (ENHANCED BACKGROUND ONLY)
              // ===============================
              Card(
                color: Colors.white.withOpacity(
                  SystemUiOpacity.resolve(
                    context: context,
                    nearSystemUi: true,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _summaryRow(
                        'Total Transactions',
                        transactions.length.toString(),
                      ),
                      const SizedBox(height: 8),
                      _summaryRow(
                        'Total Amount',
                        '₹ ${totalAmount.toStringAsFixed(2)}',
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===============================
              // TRANSACTIONS TABLE
              // ===============================
              const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _tableHeader(),
                    const Divider(height: 1),
                    ...transactions.map((t) {
                      return _tableRow(
                        date: DateFormat('dd MMM yy')
                            .format(DateTime.parse(t['date'])),
                        category: t['category_name'],
                        note: t['note'] ?? '-',
                        amount:
                            '₹ ${(t['amount'] as num).toStringAsFixed(0)}',
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===============================
              // PIE CHART
              // ===============================
              const Text(
                'Category Distribution',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              AspectRatio(
                aspectRatio: 1.2,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sections: List.generate(
                      categoryTotals.length,
                      (i) {
                        final entry =
                            categoryTotals.entries.toList()[i];
                        final percent =
                            (entry.value / totalAmount) * 100;

                        return PieChartSectionData(
                          value: entry.value,
                          title: '${percent.toStringAsFixed(1)}%',
                          radius: 70,
                          color: Colors.primaries[
                              i % Colors.primaries.length],
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===============================
              // LEGENDS
              // ===============================
              ...List.generate(
                categoryTotals.length,
                (i) {
                  final entry =
                      categoryTotals.entries.toList()[i];
                  final percent =
                      (entry.value / totalAmount) * 100;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: Colors.primaries[
                              i % Colors.primaries.length],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '₹ ${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ===============================
  // HELPERS
  // ===============================
  Widget _summaryRow(String label, String value,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 80, child: Text('Date', style: _th)),
          SizedBox(width: 90, child: Text('Category', style: _th)),
          Expanded(child: Text('Note', style: _th)),
          SizedBox(width: 70, child: Text('Amount', style: _th)),
        ],
      ),
    );
  }

  Widget _tableRow({
    required String date,
    required String category,
    required String note,
    required String amount,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(date, style: _td)),
          SizedBox(
            width: 90,
            child: Text(
              category,
              style: _td,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              note,
              style: _td,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              amount,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

const TextStyle _th = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: Colors.grey,
);

const TextStyle _td = TextStyle(
  fontSize: 12,
  color: Colors.black87,
);
