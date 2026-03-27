import '../../core/app_config.dart';
import '../../core/utils/loan_math.dart';
import '../../services/export_import_service.dart';
import '../local/database_helper.dart';
import '../models/borrower.dart';
import '../models/loan.dart';
import '../models/payment.dart';
import '../repositories/app_state_repository.dart';
import '../repositories/borrower_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/payment_repository.dart';

class SampleSeedService {
  SampleSeedService({
    required DatabaseHelper databaseHelper,
    required AppStateRepository appStateRepository,
    required BorrowerRepository borrowerRepository,
    required LoanRepository loanRepository,
    required PaymentRepository paymentRepository,
    required ExportImportService exportImportService,
  })  : _databaseHelper = databaseHelper,
        _appStateRepository = appStateRepository,
        _borrowerRepository = borrowerRepository,
        _loanRepository = loanRepository,
        _paymentRepository = paymentRepository,
        _exportImportService = exportImportService;

  final DatabaseHelper _databaseHelper;
  final AppStateRepository _appStateRepository;
  final BorrowerRepository _borrowerRepository;
  final LoanRepository _loanRepository;
  final PaymentRepository _paymentRepository;
  final ExportImportService _exportImportService;

  Future<void> seedIfEnabled() async {
    if (!AppConfig.seedSampleDataOnFirstLaunch) {
      return;
    }

    final metadata = await _appStateRepository.loadMetadata();
    if (metadata.currentVersion > 0) {
      return;
    }

    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final borrower = Borrower(
      id: 'sample-borrower-1',
      name: 'Daw Mya',
      phone: '09-123456789',
      address: 'Lanmadaw Township',
      note: 'Sample borrower',
      createdAt: now,
      updatedAt: now,
    );
    final totalRepayable = LoanMath.totalRepayable(
      principal: 500000,
      interestValue: 10,
      interestType: LoanMath.percentage,
    );
    final loan = Loan(
      id: 'sample-loan-1',
      borrowerId: borrower.id,
      principal: 500000,
      interestValue: 10,
      interestType: LoanMath.percentage,
      totalRepayable: totalRepayable,
      amountPaid: 100000,
      remainingAmount: totalRepayable - 100000,
      startDate: '2026-03-01',
      dueDate: '2026-04-01',
      status: 'active',
      note: 'Sample monthly loan',
      createdAt: now,
      updatedAt: now,
    );
    final payment = Payment(
      id: 'sample-payment-1',
      loanId: loan.id,
      amount: 100000,
      paymentDate: '2026-03-10',
      note: 'Sample payment',
      createdAt: now,
    );

    await db.transaction((txn) async {
      await _borrowerRepository.upsertBorrowerOn(txn, borrower);
      await _loanRepository.upsertLoanOn(txn, loan);
      await _paymentRepository.insertPaymentOn(txn, payment);
      await _loanRepository.recalculateLoanSnapshotOn(txn, loanId: loan.id);
      await _appStateRepository.setValuesOn(txn, {
        'current_version': '1',
        'sync_status': 'needs_export',
        'sample_seeded': 'true',
      });
    });

    await _exportImportService.writeCurrentPackage(markAsNeedingExport: true);
  }
}

