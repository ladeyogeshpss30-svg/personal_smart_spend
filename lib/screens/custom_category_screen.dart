import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ SAFE haptic

import '../services/category_service.dart';
import '../services/category_note_service.dart';
import '../models/category_model.dart';
import '../core/constants/category_icons.dart';

class CustomCategoryScreen extends StatefulWidget {
  const CustomCategoryScreen({super.key});

  @override
  State<CustomCategoryScreen> createState() =>
      _CustomCategoryScreenState();
}

class _CustomCategoryScreenState extends State<CustomCategoryScreen> {
  final CategoryService _service = CategoryService();
  final CategoryNoteService _noteService = CategoryNoteService();

  late Future<List<Category>> _categoriesFuture;

  static const int _maxCustomCategories = 5;

  List<String>? _editingNotes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _categoriesFuture = _service.getCustomCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data!;
          if (list.isEmpty) return const _EmptyState();

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];

              final iconCode =
                  int.tryParse(c.icon ?? '') ??
                      CategoryIcons.icons.first.codePoint;

              final iconData =
                  IconData(iconCode, fontFamily: 'MaterialIcons');
              final iconColor =
                  CategoryIcons.colorForIcon(iconData);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(iconData, color: iconColor),
                ),
                title: Text(c.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _openCategorySheet(category: c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCategory(c),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addCategory() async {
    final count = await _service.getCustomCategoryCount();
    if (!mounted) return;

    if (count >= _maxCustomCategories) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content:
              Text('You can add up to 5 custom categories only.'),
        ),
      );
      return;
    }

    _openCategorySheet();
  }

  void _deleteCategory(Category c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text(
          'All expenses under this category will be moved to "Unknown".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _service.deleteCustomCategory(c.id!);
              Navigator.pop(context);
              setState(_load);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ADD / EDIT CATEGORY SHEET (KEYBOARD SAFE ✅)
  // =====================================================
  Future<void> _openCategorySheet({Category? category}) async {
    final nameCtrl =
        TextEditingController(text: category?.name ?? '');
    final TextEditingController noteCtrl = TextEditingController();

    int selectedIconCode =
        int.tryParse(category?.icon ?? '') ??
            CategoryIcons.icons.first.codePoint;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return FutureBuilder<List<String>>(
              future: category == null
                  ? Future.value([])
                  : _noteService.getNotesByCategory(category.id!),
              builder: (context, snapshot) {
                if (_editingNotes == null &&
                    snapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                _editingNotes ??= snapshot.data ?? [];

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          category == null
                              ? 'Add Category'
                              : 'Edit Category',
                          style:
                              Theme.of(context).textTheme.titleLarge,
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),

                      const _InfoText(),
                      const SizedBox(height: 16),

                      TextField(
                        controller: nameCtrl,
                        maxLength: 20,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _IconGrid(
                        icons: CategoryIcons.icons,
                        selectedIcon: selectedIconCode,
                        onSelect: (code) {
                          setLocalState(() =>
                              selectedIconCode = code);
                        },
                      ),

                      const SizedBox(height: 24),

                      ExpansionTile(
                        title:
                            const Text('Default Notes (Optional)'),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: noteCtrl,
                                  maxLength: 20,
                                  decoration:
                                      const InputDecoration(
                                    hintText: 'Add default note',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.teal,
                                ),
                                onPressed: () {
                                  final text =
                                      noteCtrl.text.trim();
                                  if (text.isEmpty) return;

                                  if (_editingNotes!.length >= 5) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        behavior:
                                            SnackBarBehavior.floating,
                                        content: Text(
                                          'You can add up to 5 default notes only.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setLocalState(() {
                                    _editingNotes!.add(text);
                                    noteCtrl.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                _editingNotes!.map((note) {
                              return Chip(
                                label: Text(note),
                                onDeleted: () {
                                  setLocalState(() {
                                    _editingNotes!.remove(note);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(),

                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              _editingNotes = null;
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () async {
                              if (category == null) {
                                final id =
                                    await _service.addCustomCategory(
                                  name: nameCtrl.text.trim(),
                                  color: Colors.teal.value,
                                  icon:
                                      selectedIconCode.toString(),
                                );

                                for (final note
                                    in _editingNotes!) {
                                  await _noteService.addNote(
                                    categoryId: id,
                                    note: note,
                                  );
                                }
                              } else {
                                await _service.updateCustomCategory(
                                  id: category.id!,
                                  name: nameCtrl.text.trim(),
                                  color: Colors.teal.value,
                                  icon:
                                      selectedIconCode.toString(),
                                );

                                await _noteService
                                    .deleteNotesByCategory(
                                        category.id!);
                                for (final note
                                    in _editingNotes!) {
                                  await _noteService.addNote(
                                    categoryId: category.id!,
                                    note: note,
                                  );
                                }
                              }

                              _editingNotes = null;
                              Navigator.pop(context);
                              setState(_load);
                            },
                            child: const Text('Save Category'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ===============================
// SMALL REUSABLE WIDGETS
// ===============================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined,
              size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No custom categories yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'You can add up to 5 custom categories.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText();

  @override
  Widget build(BuildContext context) {
    return Text(
      '• Max 5 custom categories\n• Max 5 default notes per category',
      style:
          TextStyle(fontSize: 12, color: Colors.grey.shade700),
    );
  }
}

// ===============================
// COLORFUL ICON GRID
// ===============================
class _IconGrid extends StatelessWidget {
  final List<IconData> icons;
  final int selectedIcon;
  final ValueChanged<int> onSelect;

  const _IconGrid({
    required this.icons,
    required this.selectedIcon,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: icons.map((icon) {
        final isSelected = icon.codePoint == selectedIcon;
        final color = CategoryIcons.colorForIcon(icon);

        return GestureDetector(
          onTap: () => onSelect(icon.codePoint),
          child: AnimatedScale(
            scale: isSelected ? 1.08 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: color, width: 2)
                    : null,
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
