import 'package:sqflite/sqflite.dart';

import '../../core/utils/loan_math.dart';
import '../local/database_helper.dart';
import '../models/loan.dart';

class LoanRepository {
  LoanRepository(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<List<Loan>> getLoansByBorrower(String borrowerId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'loans',
      where: 'borrower_id = ?',
      whereArgs: [borrowerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<Loan?> getLoanById(String loanId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'loans',
      where: 'id = ?',
      whereArgs: [loanId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Loan.fromMap(rows.first);
  }

  Future<void> upsertLoanOn(DatabaseExecutor executor, Loan loan) async {
    await executor.insert(
      'loans',
      loan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Loan>> getAllLoans() async {
    final db = await _databaseHelper.database;
    final rows = await db.query('loans', orderBy: 'created_at DESC');
    return rows.map(Loan.fromMap).toList();
  }

  Future<void> recalculateLoanSnapshotOn(
    DatabaseExecutor executor, {
    String? loanId,
  }) async {
    final loans = loanId == null
        ? await executor.query('loans')
        : await executor.query(
            'loans',
            where: 'id = ?',
            whereArgs: [loanId],
          );

    for (final row in loans) {
      final currentLoan = Loan.fromMap(row);
      final paymentRows = await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total_paid
        FROM payments
        WHERE loan_id = ?
        ''',
        [currentLoan.id],
      );

      final amountPaid =
          (paymentRows.first['total_paid'] as num?)?.toDouble() ?? 0;
      final remainingAmount = LoanMath.remaining(
        totalRepayable: currentLoan.totalRepayable,
        amountPaid: amountPaid,
      );

      await executor.update(
        'loans',
        {
          'amount_paid': amountPaid,
          'remaining_amount': remainingAmount,
          'status': deriveStatus(
            dueDate: currentLoan.dueDate,
            remainingAmount: remainingAmount,
          ),
        },
        where: 'id = ?',
        whereArgs: [currentLoan.id],
      );
    }
  }

  String deriveStatus({
    required String? dueDate,
    required double remainingAmount,
  }) {
    if (remainingAmount <= 0) {
      return 'closed';
    }

    if (dueDate != null && dueDate.isNotEmpty) {
      final due = DateTime.parse(dueDate);
      final today = DateTime.now();
      final onlyDate = DateTime(today.year, today.month, today.day);
      if (due.isBefore(onlyDate)) {
        return 'overdue';
      }
    }

    return 'active';
  }
}

