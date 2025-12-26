import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/income_model.dart';
import '../services/income_service.dart';

// ✅ Income source constants with icons
import '../core/constants/income_sources.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final IncomeService _service = IncomeService();

  // ✅ Use source key (analytics-safe)
  String _sourceKey = IncomeSources.items.first.key;

  // ✅ NEW: editable date (defaults to today)
  DateTime _selectedDate = DateTime.now();

  // ===============================
  // DATE PICKER
  // ===============================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ===============================
  // SAVE INCOME
  // ===============================
  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    await _service.addIncome(
      Income(
        amount: amount,
        source: _sourceKey,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        note: _noteCtrl.text.trim(),
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Income')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===============================
            // AMOUNT
            // ===============================
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),

            // ===============================
            // SOURCE (ICON-BASED)
            // ===============================
            DropdownButtonFormField<String>(
              value: _sourceKey,
              decoration:
                  const InputDecoration(labelText: 'Income Source'),
              items: IncomeSources.items.map((item) {
                return DropdownMenuItem<String>(
                  value: item.key,
                  child: Row(
                    children: [
                      Icon(item.icon, size: 18),
                      const SizedBox(width: 10),
                      Text(item.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sourceKey = value);
                }
              },
            ),

            const SizedBox(height: 12),

            // ===============================
            // NOTE
            // ===============================
            TextField(
              controller: _noteCtrl,
              decoration:
                  const InputDecoration(labelText: 'Note (optional)'),
            ),

            const SizedBox(height: 12),

            // ===============================
            // DATE PICKER (NEW)
            // ===============================
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                DateFormat('dd MMM yyyy').format(_selectedDate),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),

            const SizedBox(height: 24),

            // ===============================
            // SAVE
            // ===============================
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Income'),
            ),
          ],
        ),
      ),
    );
  }
}
