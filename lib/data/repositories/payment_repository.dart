import 'package:sqflite/sqflite.dart';

import '../local/database_helper.dart';
import '../models/payment.dart';

class PaymentRepository {
  PaymentRepository(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<List<Payment>> getPaymentsForLoan(String loanId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'payments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'payment_date DESC, created_at DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'payments',
      orderBy: 'payment_date DESC, created_at DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<void> insertPaymentOn(
    DatabaseExecutor executor,
    Payment payment,
  ) async {
    await executor.insert('payments', payment.toMap());
  }

  Future<void> deletePaymentsForLoanOn(
    DatabaseExecutor executor,
    String loanId,
  ) async {
    await executor.delete(
      'payments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
    );
  }

  Future<void> deletePaymentsForBorrowerOn(
    DatabaseExecutor executor,
    String borrowerId,
  ) async {
    await executor.delete(
      'payments',
      where: 'loan_id IN (SELECT id FROM loans WHERE borrower_id = ?)',
      whereArgs: [borrowerId],
    );
  }
}
