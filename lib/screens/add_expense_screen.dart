import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/expense_model.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';
import '../services/category_note_service.dart';
import '../core/constants/default_category_notes.dart';
import '../core/utils/category_icon_mapper.dart';
import '../core/constants/category_icons.dart';
import '../core/theme/system_ui_opacity.dart'; // ✅ NEW (MANDATORY)

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final ExpenseService _expenseService = ExpenseService();
  final CategoryService _categoryService = CategoryService();
  final CategoryNoteService _noteService = CategoryNoteService();

  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  Future<List<Category>>? _categoriesFuture;
  List<String> _categoryNotes = [];

  bool _isSaving = false;

  // ===============================
  // INIT
  // ===============================
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // ===============================
  // LOAD CATEGORIES
  // ===============================
  Future<void> _loadCategories() async {
    await _categoryService.ensureDefaultCategories();
    final categories = await _categoryService.getAllCategories();

    if (!mounted || categories.isEmpty) return;

    setState(() {
      _categoriesFuture = Future.value(categories);
      _selectedCategory = categories.first;
    });

    await _loadCategoryNotes(_selectedCategory!);
  }

  // ===============================
  // LOAD CATEGORY NOTES
  // ===============================
  Future<void> _loadCategoryNotes(Category category) async {
    _noteController.clear();

    final defaultNotes =
        DefaultCategoryNotes.notes[category.name] ??
        await _noteService.getNotesByCategory(category.id!);

    await _noteService.insertDefaultNotesIfNeeded(
      category.id!,
      defaultNotes,
    );

    final notes =
        await _noteService.getNotesByCategory(category.id!);

    if (!mounted) return;

    setState(() {
      _selectedCategory = category;
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
  // SAVE EXPENSE
  // ===============================
  Future<void> _saveExpense() async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter amount and category')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amount')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final expense = Expense(
        amount: amount,
        categoryId: _selectedCategory!.id!,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        note: _noteController.text.trim(),
      );

      await _expenseService.addExpense(expense);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ===============================
  // UI (KEYBOARD SAFE ✅)
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Add Expense')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Container(
            // ✅ MAIN FORM CONTAINER (ENHANCED ONLY)
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withOpacity(
                    SystemUiOpacity.resolve(
                      context: context,
                      nearSystemUi: true,
                    ),
                  ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AMOUNT
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Amount'),
                ),

                const SizedBox(height: 16),

                // CATEGORY
                FutureBuilder<List<Category>>(
                  future: _categoriesFuture,
                  builder: (_, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final categories = snapshot.data!;

                    return DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                          labelText: 'Category'),
                      items: categories.map((c) {
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
                                  color: iconColor,
                                  size: 16,
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
                    runSpacing: 6,
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

                const SizedBox(height: 16),

                // DATE
                Row(
                  children: [
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Select Date'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // NOTE
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Note (optional)'),
                ),

                const SizedBox(height: 24),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveExpense,
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text('Save Expense'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
