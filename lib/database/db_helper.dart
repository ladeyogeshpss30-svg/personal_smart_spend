import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Required for Windows desktop SQLite
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  // 🔥 DATABASE VERSION (BUMPED FOR INCOME MODULE)
  static const int _dbVersion = 3;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'personal_smart_spend.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ==============================
  // CREATE DATABASE (FRESH INSTALL)
  // ==============================
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createCategoriesTable);
    await db.execute(_createExpensesTable);
    await db.execute(_createBudgetsTable);
    await db.execute(_createAlertsTable);
    await db.execute(_createPreferencesTable);
    await db.execute(_createCategoryNotesTable);

    // 🆕 INCOME TABLE
    await db.execute(_createIncomeTable);

    await db.execute(_indexExpenseDate);
    await db.execute(_indexExpenseCategory);
    await db.execute(_indexCategoryNotesCategory);

    await _insertSystemCategories(db);
  }

  // ==============================
  // UPGRADE DATABASE (EXISTING USERS)
  // ==============================
  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // 🔧 FIX alerts table
      await db.execute('DROP TABLE IF EXISTS alerts');
      await db.execute(_createAlertsTable);

      // 🔧 Ensure categories compatibility
      await db.execute(
        'ALTER TABLE categories ADD COLUMN is_system INTEGER NOT NULL DEFAULT 1',
      );

      await _insertSystemCategories(db);
    }

    // 🆕 ADD INCOME TABLE (SAFE MIGRATION)
    if (oldVersion < 3) {
      await db.execute(_createIncomeTable);
    }
  }

  // ==============================
  // TABLE DEFINITIONS
  // ==============================

  /// ✅ categories
  static const String _createCategoriesTable = '''
  CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    icon TEXT,
    color INTEGER,
    is_system INTEGER NOT NULL
  );
  ''';

  /// ✅ expenses
  static const String _createExpensesTable = '''
  CREATE TABLE expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL CHECK(amount >= 0),
    category_id INTEGER NOT NULL,
    date TEXT NOT NULL,
    note TEXT,
    FOREIGN KEY (category_id) REFERENCES categories(id)
  );
  ''';

  /// ✅ budgets
  static const String _createBudgetsTable = '''
  CREATE TABLE budgets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    amount REAL NOT NULL CHECK(amount >= 0),
    month TEXT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id)
  );
  ''';

  /// ✅ alerts
  static const String _createAlertsTable = '''
  CREATE TABLE alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER,
    threshold REAL NOT NULL,
    period TEXT NOT NULL,
    triggered_at TEXT,
    FOREIGN KEY (category_id) REFERENCES categories(id)
  );
  ''';

  /// preferences
  static const String _createPreferencesTable = '''
  CREATE TABLE preferences (
    key TEXT PRIMARY KEY,
    value TEXT
  );
  ''';

  /// category notes
  static const String _createCategoryNotesTable = '''
  CREATE TABLE category_notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER NOT NULL,
    note TEXT NOT NULL,
    is_default INTEGER DEFAULT 1,
    FOREIGN KEY (category_id) REFERENCES categories(id)
  );
  ''';

  /// 🆕 income (NEW MODULE)
  static const String _createIncomeTable = '''
  CREATE TABLE income (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL CHECK(amount >= 0),
    source TEXT NOT NULL,
    date TEXT NOT NULL,
    note TEXT
  );
  ''';

  // ==============================
  // INDEXES
  // ==============================
  static const String _indexExpenseDate =
      'CREATE INDEX idx_expenses_date ON expenses(date);';

  static const String _indexExpenseCategory =
      'CREATE INDEX idx_expenses_category ON expenses(category_id);';

  static const String _indexCategoryNotesCategory =
      'CREATE INDEX idx_category_notes_category ON category_notes(category_id);';

  // ==============================
  // SYSTEM DATA
  // ==============================
  Future<void> _insertSystemCategories(Database db) async {
    await db.insert(
      'categories',
      {
        'name': 'Unknown',
        'icon': '❓',
        'color': 0xFF9E9E9E,
        'is_system': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
