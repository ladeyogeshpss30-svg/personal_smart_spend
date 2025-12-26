import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/db_helper.dart';
import '../models/category_model.dart';

class CategoryService {
  final DBHelper _dbHelper = DBHelper();

  // =====================================================
  // 🔒 FORCE DEFAULT SYSTEM CATEGORIES (ONE TIME)
  // =====================================================
  Future<void> insertDefaultCategoriesIfNeeded() async {
    final db = await _dbHelper.database;

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );

    if (count != null && count > 1) return;

    final defaults = [
      ['Food', Colors.orange, 'food'],
      ['Bills', Colors.blue, 'bills'],
      ['Transport', Colors.green, 'transport'],
      ['Shopping', Colors.purple, 'shopping'],
      ['Entertainment', Colors.red, 'entertainment'],
      ['Health', Colors.teal, 'health'],
      ['Invest', Colors.indigo, 'invest'],
      ['Lending / Support', Colors.brown, 'lending'],
    ];

    for (final d in defaults) {
      await db.insert(
        'categories',
        {
          'name': d[0],
          'color': (d[1] as Color).value,
          'icon': d[2],
          'is_system': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await db.insert(
      'categories',
      {
        'name': 'Unknown',
        'color': Colors.grey.value,
        'icon': 'unknown',
        'is_system': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // =====================================================
  // 📥 FETCH METHODS
  // =====================================================
  Future<List<Category>> getCategories() async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'categories',
      orderBy: 'is_system DESC, name ASC',
    );

    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<List<Category>> getCustomCategories() async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'categories',
      where: 'is_system = 0',
      orderBy: 'name ASC',
    );

    return result.map((e) => Category.fromMap(e)).toList();
  }

  // =====================================================
  // ➕ CUSTOM CATEGORY RULES
  // =====================================================
  Future<int> getCustomCategoryCount() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM categories WHERE is_system = 0',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // =====================================================
  // ✅ FIXED: ADD CUSTOM CATEGORY (RETURNS ID)
  // =====================================================
  Future<int> addCustomCategory({
    required String name,
    required int color,
    String? icon,
  }) async {
    final count = await getCustomCategoryCount();
    if (count >= 5) {
      throw Exception('Maximum 5 custom categories allowed');
    }

    final db = await _dbHelper.database;

    final int id = await db.insert(
      'categories',
      {
        'name': name,
        'color': color,
        'icon': icon,
        'is_system': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return id;
  }

  // =====================================================
  // ✏️ UPDATE CUSTOM CATEGORY
  // =====================================================
  Future<void> updateCustomCategory({
    required int id,
    required String name,
    required int color,
    String? icon,
  }) async {
    final db = await _dbHelper.database;

    await db.update(
      'categories',
      {
        'name': name,
        'color': color,
        'icon': icon,
      },
      where: 'id = ? AND is_system = 0',
      whereArgs: [id],
    );
  }

  // =====================================================
  // 🗑 DELETE CUSTOM CATEGORY (SAFE)
  // =====================================================
  Future<void> deleteCustomCategory(int categoryId) async {
    final db = await _dbHelper.database;

    final unknown = await db.query(
      'categories',
      where: 'name = ? AND is_system = 1',
      whereArgs: ['Unknown'],
      limit: 1,
    );

    if (unknown.isEmpty) {
      throw Exception('Unknown category not found');
    }

    final unknownId = unknown.first['id'];

    await db.update(
      'expenses',
      {'category_id': unknownId},
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );

    await db.delete(
      'categories',
      where: 'id = ? AND is_system = 0',
      whereArgs: [categoryId],
    );
  }

  // =====================================================
  // 🔁 BACKWARD COMPATIBILITY (DO NOT REMOVE)
  // =====================================================
  Future<void> ensureDefaultCategories() async {
    await insertDefaultCategoriesIfNeeded();
  }

  Future<List<Category>> getAllCategories() async {
    return getCategories();
  }
}
