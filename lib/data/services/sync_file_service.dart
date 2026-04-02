import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_config.dart';
import '../../core/utils/loan_math.dart';
import '../local/database_helper.dart';
import '../models/import_candidate.dart';
import '../models/sync_package.dart';
import '../repositories/app_state_repository.dart';
import '../repositories/borrower_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/payment_repository.dart';

class SyncFileService {
  SyncFileService({
    required DatabaseHelper databaseHelper,
    required AppStateRepository appStateRepository,
    required BorrowerRepository borrowerRepository,
    required LoanRepository loanRepository,
    required PaymentRepository paymentRepository,
  })  : _databaseHelper = databaseHelper,
        _appStateRepository = appStateRepository,
        _borrowerRepository = borrowerRepository,
        _loanRepository = loanRepository,
        _paymentRepository = paymentRepository;

  final DatabaseHelper _databaseHelper;
  final AppStateRepository _appStateRepository;
  final BorrowerRepository _borrowerRepository;
  final LoanRepository _loanRepository;
  final PaymentRepository _paymentRepository;

  DatabaseHelper get databaseHelper => _databaseHelper;

  Future<File> writeCurrentPackage() async {
    final package = await buildCurrentPackage();
    final exportFile = await currentExportFile();
    await exportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(package.toJson()),
    );
    return exportFile;
  }

  Future<SyncPackage> buildCurrentPackage() async {
    final metadata = await _appStateRepository.loadMetadata();
    final borrowers = await _borrowerRepository.getAllBorrowers();
    final loans = await _loanRepository.getAllLoans();
    final payments = await _paymentRepository.getAllPayments();

    return SyncPackage(
      appVersion: AppConfig.supportedPackageVersion,
      dataVersion: metadata.currentVersion,
      exportedAt: DateTime.now().toIso8601String(),
      exportedBy: metadata.deviceName,
      borrowers: borrowers,
      loans: loans,
      payments: payments,
    );
  }

  Future<ImportCandidate> prepareImportCandidate({
    required String filePath,
    required int currentVersion,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ImportCandidate(
        filePath: filePath,
        canImport: false,
        message: 'File not found.',
      );
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid file structure.');
      }

      if (!decoded.containsKey('dataVersion')) {
        throw const FormatException('Missing dataVersion.');
      }

      final package = SyncPackage.fromJson(decoded);
      if (package.appVersion != AppConfig.supportedPackageVersion) {
        return ImportCandidate(
          filePath: filePath,
          package: package,
          canImport: false,
          message: 'This update file version is not supported.',
        );
      }

      if (package.dataVersion <= currentVersion) {
        return ImportCandidate(
          filePath: filePath,
          package: package,
          canImport: false,
          message: 'This file is not newer than the data already on this phone.',
        );
      }

      return ImportCandidate(
        filePath: filePath,
        package: package,
        canImport: true,
        message: 'A newer update was found. Import it now.',
      );
    } on FormatException {
      return ImportCandidate(
        filePath: filePath,
        canImport: false,
        message: 'This file is not a valid Money Loan Sync update.',
      );
    } on Object {
      return ImportCandidate(
        filePath: filePath,
        canImport: false,
        message: 'This file is not a valid Money Loan Sync update.',
      );
    }
  }

  Future<File?> createBackup() async {
    final metadata = await _appStateRepository.loadMetadata();
    if (metadata.currentVersion <= 0) {
      return null;
    }

    final backupDirectory = await _backupDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('.', '');
    final backupFile = File(
      p.join(
        backupDirectory.path,
        'moneyloan_backup_v${metadata.currentVersion}_$timestamp.mloan',
      ),
    );

    final package = await buildCurrentPackage();
    await backupFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(package.toJson()),
    );
    return backupFile;
  }

  Future<void> importPackage(SyncPackage package) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('loans');
      await txn.delete('borrowers');

      for (final borrower in package.borrowers) {
        await _borrowerRepository.upsertBorrowerOn(txn, borrower);
      }
      for (final loan in package.loans) {
        await _loanRepository.upsertLoanOn(
          txn,
          loan.copyWith(
            totalRepayable: LoanMath.totalRepayable(
              principal: loan.principal,
              interestValue: loan.interestValue,
              interestType: loan.interestType,
            ),
          ),
        );
      }
      for (final payment in package.payments) {
        await _paymentRepository.insertPaymentOn(txn, payment);
      }

      await _loanRepository.recalculateLoanSnapshotOn(txn);
      await _appStateRepository.setValuesOn(txn, {
        'current_version': package.dataVersion.toString(),
        'last_imported_at': DateTime.now().toIso8601String(),
        'pending_import_path': '',
        'pending_import_version': '',
        'sync_status': 'ready',
      });
    });
  }

  Future<File> currentExportFile() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return File(p.join(documentsDirectory.path, AppConfig.syncFileName));
  }

  Future<Directory> _backupDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documentsDirectory.path, 'backups'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
