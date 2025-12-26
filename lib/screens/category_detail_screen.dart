import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/analytics_service.dart';
import '../core/enums/analytics_time_frame.dart';
import '../core/utils/analytics_date_resolver.dart';

class CategoryDetailScreen extends StatelessWidget {
  final int categoryId;
  final String categoryName;
  final AnalyticsTimeFrame timeFrame;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.timeFrame,
  });

  // ===============================
  // LOAD TRANSACTIONS (PIE DRILL-DOWN)
  // ===============================
  Future<List<Map<String, dynamic>>> _loadTransactions(
    AnalyticsService service,
  ) {
    final range = AnalyticsDateResolver.resolve(timeFrame);

    return service.getTransactionsByCategory(
      categoryId: categoryId,
      fromDate: range.fromDate,
      toDate: range.toDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AnalyticsService service = AnalyticsService();

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadTransactions(service),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No records found',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final e = items[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===============================
                        // AMOUNT (LEFT)
                        // ===============================
                        SizedBox(
                          width: 110,
                          child: Text(
                            '₹ ${(e['amount'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ===============================
                        // NOTE + DATE (RIGHT)
                        // ===============================
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (e['note'] != null &&
                                  e['note'].toString().isNotEmpty)
                                Text(
                                  e['note'].toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              Text(
                                DateFormat('dd MMM yyyy').format(
                                  DateTime.parse(e['date']),
                                ),
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

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
