import 'package:sqflite/sqflite.dart';

import '../local/database_helper.dart';
import '../models/borrower.dart';

class BorrowerRepository {
  BorrowerRepository(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<List<Borrower>> getAllBorrowers() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'borrowers',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Borrower.fromMap).toList();
  }

  Future<Borrower?> getBorrowerById(String borrowerId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'borrowers',
      where: 'id = ?',
      whereArgs: [borrowerId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Borrower.fromMap(rows.first);
  }

  Future<void> upsertBorrowerOn(
    DatabaseExecutor executor,
    Borrower borrower,
  ) async {
    await executor.insert(
      'borrowers',
      borrower.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBorrowerOn(
    DatabaseExecutor executor,
    String borrowerId,
  ) async {
    await executor.delete(
      'borrowers',
      where: 'id = ?',
      whereArgs: [borrowerId],
    );
  }
}
