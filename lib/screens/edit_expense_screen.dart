import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/expense_model.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../services/category_note_service.dart';
import '../core/constants/default_category_notes.dart';
import '../core/utils/category_key_helper.dart';
import '../core/utils/category_icon_mapper.dart';
import '../core/constants/category_icons.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({
    super.key,
    required this.expense,
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final ExpenseService _expenseService = ExpenseService();
  final CategoryService _categoryService = CategoryService();
  final CategoryNoteService _noteService = CategoryNoteService();

  List<String> _categoryNotes = [];

  late Category _selectedCategory;
  late DateTime _selectedDate;
  late Future<List<Category>> _categoriesFuture;

  bool _isSaving = false;

  // ===============================
  // INIT
  // ===============================
  @override
  void initState() {
    super.initState();

    _amountController.text = widget.expense.amount.toString();
    _noteController.text = widget.expense.note ?? '';
    _selectedDate = DateTime.parse(widget.expense.date);

    _categoriesFuture =
        _categoryService.getAllCategories().then((categories) {
      _selectedCategory = categories.firstWhere(
        (c) => c.id == widget.expense.categoryId,
      );
      _loadCategoryNotes(_selectedCategory);
      return categories;
    });
  }

  // ===============================
  // LOAD CATEGORY NOTES
  // ===============================
  Future<void> _loadCategoryNotes(Category category) async {
    final key = CategoryKeyHelper.normalize(category.name);

    final defaultNotes = DefaultCategoryNotes.notes[key] ?? [];

    await _noteService.insertDefaultNotesIfNeeded(
      category.id!,
      defaultNotes,
    );

    final notes =
        await _noteService.getNotesByCategory(category.id!);

    if (!mounted) return;

    setState(() {
      _categoryNotes = notes;
    });
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

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  // ===============================
  // SAVE
  // ===============================
  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);

    try {
      await _expenseService.updateExpense(
        Expense(
          id: widget.expense.id,
          amount: amount,
          categoryId: _selectedCategory.id!,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          note: _noteController.text.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // AMOUNT
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),

            const SizedBox(height: 12),

            // CATEGORY (✅ FIXED ICON + COLOR)
            FutureBuilder<List<Category>>(
              future: _categoriesFuture,
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: snapshot.data!.map((c) {
                    final iconData =
                        CategoryIconMapper.getIcon(c.icon);
                    final iconColor =
                        CategoryIcons.colorForIcon(iconData);

                    return DropdownMenuItem<Category>(
                      value: c,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                iconColor.withOpacity(0.15),
                            child: Icon(
                              iconData,
                              size: 16,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                        _noteController.clear();
                      });
                      _loadCategoryNotes(value);
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            // CATEGORY NOTE CHIPS
            if (_categoryNotes.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _categoryNotes.map((note) {
                  return ChoiceChip(
                    label: Text(note),
                    selected: _noteController.text == note,
                    onSelected: (_) {
                      setState(() {
                        _noteController.text = note;
                      });
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // NOTE FIELD
            TextField(
              controller: _noteController,
              decoration:
                  const InputDecoration(labelText: 'Note (optional)'),
            ),

            const SizedBox(height: 24),

            // SAVE BUTTON
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
