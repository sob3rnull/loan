import '../local/database_helper.dart';
import '../models/dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<DashboardSummary> loadSummary() async {
    final db = await _databaseHelper.database;
    final totalsRows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(principal), 0) AS total_principal,
        COUNT(*) AS total_loans
      FROM loans
    ''');
    final activeRows = await db.rawQuery('''
      SELECT
        COUNT(*) AS active_count,
        COALESCE(SUM(remaining_amount), 0) AS total_remaining
      FROM loans
      WHERE remaining_amount > 0
    ''');
    final collectedRows = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total_collected
      FROM payments
    ''');
    final overdueRows = await db.rawQuery('''
      SELECT COUNT(*) AS overdue_count
      FROM loans
      WHERE remaining_amount > 0
        AND due_date IS NOT NULL
        AND due_date != ''
        AND DATE(due_date) < DATE('now')
    ''');

    return DashboardSummary(
      activeLoansCount: (activeRows.first['active_count'] as num).toInt(),
      totalPrincipal:
          (totalsRows.first['total_principal'] as num).toDouble(),
      totalCollected:
          (collectedRows.first['total_collected'] as num).toDouble(),
      totalRemaining:
          (activeRows.first['total_remaining'] as num).toDouble(),
      overdueLoansCount: (overdueRows.first['overdue_count'] as num).toInt(),
    );
  }
}
