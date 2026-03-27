import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _databaseName = 'money_loan.db';
  static const int _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databasePath = p.join(documentsDirectory.path, _databaseName);
    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedDefaultState(db);
      },
    );
    return _database!;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE borrowers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        note TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        borrower_id TEXT NOT NULL,
        principal REAL NOT NULL,
        interest_value REAL NOT NULL,
        interest_type TEXT NOT NULL,
        total_repayable REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        remaining_amount REAL NOT NULL,
        start_date TEXT,
        due_date TEXT,
        status TEXT NOT NULL,
        note TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        loan_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        note TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE app_state (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_loans_borrower_id ON loans (borrower_id)',
    );
    await db.execute(
      'CREATE INDEX idx_payments_loan_id ON payments (loan_id)',
    );
  }

  Future<void> _seedDefaultState(Database db) async {
    const defaults = <String, String>{
      'current_version': '0',
      'last_imported_at': '',
      'last_exported_at': '',
      'last_exported_version': '',
      'sync_status': 'ready',
      'device_name': 'This Phone',
      'pending_import_path': '',
      'pending_import_version': '',
      'sample_seeded': 'false',
    };

    for (final entry in defaults.entries) {
      await db.insert('app_state', {
        'key': entry.key,
        'value': entry.value,
      });
    }
  }
}

