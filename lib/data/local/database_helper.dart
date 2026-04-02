import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _databaseName = 'money_loan.db';
  static const int _databaseVersion = 2;

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
      onOpen: (db) async {
        await _ensureDefaultStateRows(db);
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedDefaultState(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToVersion2(db);
        }
        await _ensureDefaultStateRows(db);
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
        updated_at TEXT,
        FOREIGN KEY (borrower_id) REFERENCES borrowers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        loan_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        note TEXT,
        created_at TEXT,
        FOREIGN KEY (loan_id) REFERENCES loans (id) ON DELETE CASCADE
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
      'CREATE INDEX idx_loans_due_date ON loans (due_date)',
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

  Future<void> _ensureDefaultStateRows(Database db) async {
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
      await db.insert(
        'app_state',
        {
          'key': entry.key,
          'value': entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _migrateToVersion2(Database db) async {
    await db.execute('''
      CREATE TABLE borrowers_new (
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
      INSERT INTO borrowers_new (
        id,
        name,
        phone,
        address,
        note,
        created_at,
        updated_at
      )
      SELECT
        id,
        name,
        phone,
        address,
        note,
        created_at,
        updated_at
      FROM borrowers
    ''');

    await db.execute('''
      CREATE TABLE loans_new (
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
        updated_at TEXT,
        FOREIGN KEY (borrower_id) REFERENCES borrowers_new (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      INSERT INTO loans_new (
        id,
        borrower_id,
        principal,
        interest_value,
        interest_type,
        total_repayable,
        amount_paid,
        remaining_amount,
        start_date,
        due_date,
        status,
        note,
        created_at,
        updated_at
      )
      SELECT
        id,
        borrower_id,
        principal,
        interest_value,
        interest_type,
        total_repayable,
        amount_paid,
        remaining_amount,
        start_date,
        due_date,
        status,
        note,
        created_at,
        updated_at
      FROM loans
    ''');

    await db.execute('''
      CREATE TABLE payments_new (
        id TEXT PRIMARY KEY,
        loan_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        note TEXT,
        created_at TEXT,
        FOREIGN KEY (loan_id) REFERENCES loans_new (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      INSERT INTO payments_new (
        id,
        loan_id,
        amount,
        payment_date,
        note,
        created_at
      )
      SELECT
        id,
        loan_id,
        amount,
        payment_date,
        note,
        created_at
      FROM payments
    ''');

    await db.execute('DROP TABLE payments');
    await db.execute('DROP TABLE loans');
    await db.execute('DROP TABLE borrowers');

    await db.execute('ALTER TABLE borrowers_new RENAME TO borrowers');
    await db.execute('ALTER TABLE loans_new RENAME TO loans');
    await db.execute('ALTER TABLE payments_new RENAME TO payments');

    await db.execute('DROP INDEX IF EXISTS idx_loans_borrower_id');
    await db.execute('DROP INDEX IF EXISTS idx_loans_due_date');
    await db.execute('DROP INDEX IF EXISTS idx_payments_loan_id');

    await db.execute(
      'CREATE INDEX idx_loans_borrower_id ON loans (borrower_id)',
    );
    await db.execute(
      'CREATE INDEX idx_loans_due_date ON loans (due_date)',
    );
    await db.execute(
      'CREATE INDEX idx_payments_loan_id ON payments (loan_id)',
    );
  }
}
