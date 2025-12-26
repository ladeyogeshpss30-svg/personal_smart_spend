import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/income_model.dart';
import '../services/income_service.dart';

// ✅ MANDATORY IMPORT
import '../core/constants/income_sources.dart';

class EditIncomeScreen extends StatefulWidget {
  final Income income;

  const EditIncomeScreen({super.key, required this.income});

  @override
  State<EditIncomeScreen> createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _sourceKey;
  late DateTime _selectedDate;

  final IncomeService _incomeService = IncomeService();

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.income.amount.toString());
    _noteController =
        TextEditingController(text: widget.income.note ?? '');
    _sourceKey = widget.income.source;
    _selectedDate = DateTime.parse(widget.income.date);
  }

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
  // SAVE
  // ===============================
  Future<void> _save() async {
    final amount =
        double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final updatedIncome = widget.income.copyWith(
      amount: amount,
      source: _sourceKey,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      note: _noteController.text.trim(),
    );

    await _incomeService.updateIncome(updatedIncome);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Income')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===============================
            // AMOUNT
            // ===============================
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Amount'),
            ),

            const SizedBox(height: 12),

            // ===============================
            // SOURCE (ICON + LABEL)
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
              controller: _noteController,
              decoration:
                  const InputDecoration(labelText: 'Note'),
            ),

            const SizedBox(height: 12),

            // ===============================
            // DATE
            // ===============================
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                DateFormat('dd MMM yyyy')
                    .format(_selectedDate),
              ),
              trailing:
                  const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),

            const Spacer(),

            // ===============================
            // SAVE
            // ===============================
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
