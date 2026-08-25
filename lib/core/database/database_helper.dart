import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  /// Set this to a custom path (e.g. inMemoryDatabasePath) before the first
  /// database access in tests. Leave null for normal production operation.
  static String? testDbPath;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(testDbPath ?? 'group_investment.db');
    return _database!;
  }

  /// Call this in test tearDown to close and clear the cached database
  /// so each test gets a fresh isolated instance.
  static Future<void> resetForTest() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // In web fallback or desktop FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // If a test has injected an absolute path or the in-memory sentinel,
    // use it verbatim so tests are fully isolated from production data.
    final isAbsoluteOrSpecial =
        filePath == inMemoryDatabasePath ||
        filePath.startsWith('/') ||
        (filePath.length > 2 && filePath[1] == ':');
    if (isAbsoluteOrSpecial) {
      return await openDatabase(filePath, version: 1, onCreate: _createDB);
    }

    String dbPath;
    if (Platform.isWindows) {
      final appData = Platform.environment['PROGRAMDATA'] ?? 'C:\\ProgramData';
      final dir = Directory(
        join(appData, 'GroupInvestmentManagement', 'database'),
      );
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      dbPath = join(dir.path, filePath);
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      dbPath = join(documentsDirectory.path, filePath);
    }

    return await openDatabase(dbPath, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        role TEXT NOT NULL,
        member_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        joined_date TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE contributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        amount_paise INTEGER NOT NULL,
        contribution_date TEXT NOT NULL,
        payment_mode TEXT NOT NULL,
        reference_no TEXT,
        status TEXT NOT NULL,
        approved_by TEXT,
        approved_at TEXT,
        remarks TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (member_id) REFERENCES members (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE contribution_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        amount_paise INTEGER NOT NULL,
        payment_mode TEXT NOT NULL,
        status TEXT NOT NULL,
        requested_at TEXT NOT NULL,
        reviewed_by TEXT,
        reviewed_at TEXT,
        remarks TEXT,
        FOREIGN KEY (member_id) REFERENCES members (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE investments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount_paise INTEGER NOT NULL,
        investment_date TEXT NOT NULL,
        period_months INTEGER NOT NULL,
        expected_return_paise INTEGER NOT NULL,
        actual_return_paise INTEGER DEFAULT 0,
        current_value_paise INTEGER NOT NULL,
        status TEXT NOT NULL,
        remarks TEXT,
        created_by TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE profit_distributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        investment_id INTEGER NOT NULL,
        member_id INTEGER NOT NULL,
        member_percentage REAL NOT NULL,
        profit_amount_paise INTEGER NOT NULL,
        distributed_at TEXT NOT NULL,
        FOREIGN KEY (investment_id) REFERENCES investments (id),
        FOREIGN KEY (member_id) REFERENCES members (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE withdrawals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER NOT NULL,
        amount_paise INTEGER NOT NULL,
        status TEXT NOT NULL,
        requested_at TEXT NOT NULL,
        approved_by TEXT,
        approved_at TEXT,
        remarks TEXT,
        FOREIGN KEY (member_id) REFERENCES members (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type TEXT NOT NULL,
        member_id INTEGER,
        amount_paise INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        reference_no TEXT,
        remarks TEXT,
        created_by TEXT NOT NULL,
        approved_by TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        username TEXT NOT NULL,
        action TEXT NOT NULL,
        details TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER DEFAULT 0
      )
    ''');
  }
}
