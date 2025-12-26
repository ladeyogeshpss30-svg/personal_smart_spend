import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'report_preview_screen.dart';

class ReportEntryScreen extends StatefulWidget {
  const ReportEntryScreen({super.key});

  @override
  State<ReportEntryScreen> createState() => _ReportEntryScreenState();
}

class _ReportEntryScreenState extends State<ReportEntryScreen> {
  DateTime _fromDate =
      DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===============================
            // START DATE
            // ===============================
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(format.format(_fromDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fromDate,
                  firstDate: DateTime(2020),
                  lastDate: _toDate,
                );
                if (picked != null) {
                  setState(() => _fromDate = picked);
                }
              },
            ),

            const SizedBox(height: 8),

            // ===============================
            // END DATE
            // ===============================
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End Date'),
              subtitle: Text(format.format(_toDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _toDate,
                  firstDate: _fromDate,
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _toDate = picked);
                }
              },
            ),

            const Spacer(),

            // ===============================
            // PREVIEW REPORT BUTTON
            // ===============================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('Preview Report'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportPreviewScreen(
                        fromDate: _fromDate,
                        toDate: _toDate,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
