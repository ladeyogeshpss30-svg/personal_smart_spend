import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/income_service.dart';
import '../models/income_model.dart';

// ✅ income source icons + labels
import '../core/constants/income_sources.dart';

// ✅ NEW
import 'edit_income_screen.dart';

class IncomeListScreen extends StatefulWidget {
  final String? filterSource;
  final String? title;

  const IncomeListScreen({
    super.key,
    this.filterSource,
    this.title,
  });

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  final IncomeService _service = IncomeService();

  // ===============================
  // ACTION BOTTOM SHEET
  // ===============================
  void _showActions(BuildContext context, Income income) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Income'),
              onTap: () async {
                Navigator.pop(context);
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditIncomeScreen(income: income),
                  ),
                );
                if (updated == true && mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Income'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, income.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // DELETE CONFIRMATION
  // ===============================
  Future<void> _confirmDelete(
      BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete income?'),
        content: const Text(
          'This entry will be permanently removed and analytics will update.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteIncome(id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Income'),
      ),
      body: FutureBuilder<List<Income>>(
        future: widget.filterSource == null
            ? _service.getAllIncome()
            : _service.getIncomeBySource(
                widget.filterSource!,
              ),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final list = snapshot.data!;
          if (list.isEmpty) {
            return const Center(
                child: Text('No income added'));
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final income = list[i];

              // ✅ Resolve icon + label from key
              final source =
                  IncomeSources.fromKey(income.source);

              return ListTile(
                onTap: () =>
                    _showActions(context, income),
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.green.withOpacity(0.15),
                  child: Icon(
                    source.icon,
                    color: Colors.green,
                  ),
                ),
                title: Text(
                  '₹ ${income.amount.toStringAsFixed(2)}',
                ),
                subtitle: Text(
                  '${source.label} • '
                  '${DateFormat('dd MMM yyyy').format(DateTime.parse(income.date))}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
