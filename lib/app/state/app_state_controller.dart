import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_config.dart';
import '../../core/utils/loan_math.dart';
import '../../data/models/app_metadata.dart';
import '../../data/models/borrower.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/models/import_candidate.dart';
import '../../data/models/loan.dart';
import '../../data/models/payment.dart';
import '../../data/repositories/app_state_repository.dart';
import '../../data/repositories/borrower_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/services/device_intent_service.dart';
import '../../data/services/share_service.dart';
import '../../data/services/sync_file_service.dart';
import '../app_router.dart';

class AppStateController extends ChangeNotifier {
  AppStateController({
    required AppStateRepository appStateRepository,
    required BorrowerRepository borrowerRepository,
    required LoanRepository loanRepository,
    required PaymentRepository paymentRepository,
    required DashboardRepository dashboardRepository,
    required SyncFileService syncFileService,
    required ShareService shareService,
    required DeviceIntentService deviceIntentService,
  })  : _appStateRepository = appStateRepository,
        _borrowerRepository = borrowerRepository,
        _loanRepository = loanRepository,
        _paymentRepository = paymentRepository,
        _dashboardRepository = dashboardRepository,
        _syncFileService = syncFileService,
        _shareService = shareService,
        _deviceIntentService = deviceIntentService;

  final AppStateRepository _appStateRepository;
  final BorrowerRepository _borrowerRepository;
  final LoanRepository _loanRepository;
  final PaymentRepository _paymentRepository;
  final DashboardRepository _dashboardRepository;
  final SyncFileService _syncFileService;
  final ShareService _shareService;
  final DeviceIntentService _deviceIntentService;

  final Uuid _uuid = const Uuid();
  StreamSubscription<String>? _intentSubscription;

  bool _isLoading = true;
  bool _isWorking = false;
  bool _shouldAutoOpenImportScreen = false;
  AppMetadata _metadata = AppMetadata.initial();
  DashboardSummary _summary = DashboardSummary.empty();
  List<Borrower> _borrowers = <Borrower>[];
  ImportCandidate? _importCandidate;

  bool get isLoading => _isLoading;
  bool get isWorking => _isWorking;
  bool get shouldAutoOpenImportScreen => _shouldAutoOpenImportScreen;
  AppMetadata get metadata => _metadata;
  DashboardSummary get summary => _summary;
  List<Borrower> get borrowers => _borrowers;
  ImportCandidate? get importCandidate => _importCandidate;

  bool get canEdit =>
      _metadata.syncStatus == SyncStatus.ready &&
      !_metadata.hasPendingImport;

  String? get editBlockedMessage {
    if (_metadata.hasPendingImport ||
        _metadata.syncStatus == SyncStatus.needsImport) {
      return 'Import the newer update before editing records on this phone.';
    }
    if (_metadata.syncStatus == SyncStatus.needsExport) {
      return 'Send the latest update now before making more changes.';
    }
    return null;
  }

  Future<void> initialize() async {
    try {
      await _setDeviceNameIfNeeded();
      await refresh();

      _intentSubscription =
          _deviceIntentService.incomingFiles.listen(_handleIncomingFile);

      final initialPath = await _deviceIntentService.getInitialFilePath();
      if (initialPath != null && initialPath.isNotEmpty) {
        await prepareImportFile(initialPath, autoOpen: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _metadata = await _appStateRepository.loadMetadata();
    _summary = await _dashboardRepository.loadSummary();
    _borrowers = await _borrowerRepository.getAllBorrowers();
    _importCandidate = null;

    final pendingPath = _metadata.pendingImportPath;
    if (pendingPath != null && pendingPath.isNotEmpty) {
      if (await File(pendingPath).exists()) {
        final candidate = await _syncFileService.prepareImportCandidate(
          filePath: pendingPath,
          currentVersion: _metadata.currentVersion,
        );
        if (candidate.canImport) {
          _importCandidate = candidate;
        } else {
          await _clearPendingImportState();
          _metadata = await _appStateRepository.loadMetadata();
          _importCandidate = candidate;
        }
      } else {
        await _clearPendingImportState();
        _metadata = await _appStateRepository.loadMetadata();
      }
    }

    notifyListeners();
  }

  Future<void> pickImportFile({bool autoOpen = true}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const [AppConfig.syncFileExtension],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    await prepareImportFile(result.files.single.path!, autoOpen: autoOpen);
  }

  Future<void> prepareImportFile(
    String filePath, {
    required bool autoOpen,
  }) async {
    final candidate = await _syncFileService.prepareImportCandidate(
      filePath: filePath,
      currentVersion: _metadata.currentVersion,
    );

    _importCandidate = candidate;
    _shouldAutoOpenImportScreen = autoOpen;

    if (candidate.canImport && candidate.package != null) {
      await _appStateRepository.setValues({
        'pending_import_path': filePath,
        'pending_import_version': candidate.package!.dataVersion.toString(),
        'sync_status': 'needs_import',
      });
    }

    _metadata = await _appStateRepository.loadMetadata();
    notifyListeners();
  }

  void consumeImportAutoOpenFlag() {
    _shouldAutoOpenImportScreen = false;
  }

  bool ensureCanEdit(BuildContext context) {
    if (canEdit) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(editBlockedMessage ?? 'Editing is blocked.')),
    );
    return false;
  }

  Future<bool> saveBorrowerAndPromptShare(
    BuildContext context, {
    Borrower? existingBorrower,
    required String name,
    required String phone,
    required String address,
    required String note,
  }) async {
    if (!ensureCanEdit(context)) {
      return false;
    }

    return _runMutation(context, (nextVersion) async {
      final now = DateTime.now().toIso8601String();
      final borrower = Borrower(
        id: existingBorrower?.id ?? _uuid.v4(),
        name: name,
        phone: phone.isEmpty ? null : phone,
        address: address.isEmpty ? null : address,
        note: note.isEmpty ? null : note,
        createdAt: existingBorrower?.createdAt ?? now,
        updatedAt: now,
      );

      final db = await _syncFileService.databaseHelper.database;
      await db.transaction((txn) async {
        await _borrowerRepository.upsertBorrowerOn(txn, borrower);
        await _appStateRepository.setValuesOn(txn, {
          'current_version': nextVersion.toString(),
          'sync_status': 'needs_export',
        });
      });
    });
  }

  Future<bool> deleteBorrowerAndPromptShare(
    BuildContext context, {
    required String borrowerId,
  }) async {
    if (!ensureCanEdit(context)) {
      return false;
    }

    return _runMutation(context, (nextVersion) async {
      final db = await _syncFileService.databaseHelper.database;
      await db.transaction((txn) async {
        await _paymentRepository.deletePaymentsForBorrowerOn(txn, borrowerId);
        await _loanRepository.deleteLoansByBorrowerOn(txn, borrowerId);
        await _borrowerRepository.deleteBorrowerOn(txn, borrowerId);
        await _appStateRepository.setValuesOn(txn, {
          'current_version': nextVersion.toString(),
          'sync_status': 'needs_export',
        });
      });
    });
  }

  Future<bool> saveLoanAndPromptShare(
    BuildContext context, {
    Loan? existingLoan,
    required String borrowerId,
    required double principal,
    required double interestValue,
    required String interestType,
    required String startDate,
    required String dueDate,
    required String note,
  }) async {
    if (!ensureCanEdit(context)) {
      return false;
    }

    return _runMutation(context, (nextVersion) async {
      final existingAmountPaid = existingLoan?.amountPaid ?? 0;
      final totalRepayable = LoanMath.totalRepayable(
        principal: principal,
        interestValue: interestValue,
        interestType: interestType,
      );
      final remainingAmount = LoanMath.remaining(
        totalRepayable: totalRepayable,
        amountPaid: existingAmountPaid,
      );
      final now = DateTime.now().toIso8601String();

      final loan = Loan(
        id: existingLoan?.id ?? _uuid.v4(),
        borrowerId: borrowerId,
        principal: principal,
        interestValue: interestValue,
        interestType: interestType,
        totalRepayable: totalRepayable,
        amountPaid: existingAmountPaid,
        remainingAmount: remainingAmount,
        startDate: startDate.isEmpty ? null : startDate,
        dueDate: dueDate.isEmpty ? null : dueDate,
        status: _loanRepository.deriveStatus(
          dueDate: dueDate.isEmpty ? null : dueDate,
          remainingAmount: remainingAmount,
        ),
        note: note.isEmpty ? null : note,
        createdAt: existingLoan?.createdAt ?? now,
        updatedAt: now,
      );

      final db = await _syncFileService.databaseHelper.database;
      await db.transaction((txn) async {
        await _loanRepository.upsertLoanOn(txn, loan);
        await _loanRepository.recalculateLoanSnapshotOn(txn, loanId: loan.id);
        await _appStateRepository.setValuesOn(txn, {
          'current_version': nextVersion.toString(),
          'sync_status': 'needs_export',
        });
      });
    });
  }

  Future<bool> deleteLoanAndPromptShare(
    BuildContext context, {
    required String loanId,
  }) async {
    if (!ensureCanEdit(context)) {
      return false;
    }

    return _runMutation(context, (nextVersion) async {
      final db = await _syncFileService.databaseHelper.database;
      await db.transaction((txn) async {
        await _paymentRepository.deletePaymentsForLoanOn(txn, loanId);
        await _loanRepository.deleteLoanOn(txn, loanId);
        await _appStateRepository.setValuesOn(txn, {
          'current_version': nextVersion.toString(),
          'sync_status': 'needs_export',
        });
      });
    });
  }

  Future<bool> addPaymentAndPromptShare(
    BuildContext context, {
    required String loanId,
    required double amount,
    required String paymentDate,
    required String note,
  }) async {
    if (!ensureCanEdit(context)) {
      return false;
    }

    return _runMutation(context, (nextVersion) async {
      final db = await _syncFileService.databaseHelper.database;
      await db.transaction((txn) async {
        final payment = Payment(
          id: _uuid.v4(),
          loanId: loanId,
          amount: amount,
          paymentDate: paymentDate,
          note: note.isEmpty ? null : note,
          createdAt: DateTime.now().toIso8601String(),
        );
        await _paymentRepository.insertPaymentOn(txn, payment);
        await _loanRepository.recalculateLoanSnapshotOn(txn, loanId: loanId);
        await _appStateRepository.setValuesOn(txn, {
          'current_version': nextVersion.toString(),
          'sync_status': 'needs_export',
        });
      });
    });
  }

  Future<bool> importPendingUpdate(BuildContext context) async {
    final candidate = _importCandidate;
    if (candidate == null || !candidate.canImport || candidate.package == null) {
      return false;
    }

    _setWorking(true);
    try {
      await _syncFileService.createBackup();
      await _syncFileService.importPackage(candidate.package!);
      _importCandidate = null;
      await refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import completed successfully.')),
        );
      }
      return true;
    } finally {
      _setWorking(false);
    }
  }

  Future<bool> shareLatestUpdate(BuildContext context) async {
    if (_metadata.currentVersion <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No records are available to send yet.')),
        );
      }
      return false;
    }

    if (_metadata.syncStatus == SyncStatus.needsImport ||
        _metadata.hasPendingImport) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import the newer update before sending from this phone.'),
          ),
        );
      }
      return false;
    }

    _setWorking(true);
    try {
      final file = await _syncFileService.writeCurrentPackage();
      final shared = await _shareService.shareUpdateFile(
        filePath: file.path,
        version: _metadata.currentVersion,
        deviceName: _metadata.deviceName,
      );

      if (shared) {
        await _appStateRepository.setValues({
          'last_exported_at': DateTime.now().toIso8601String(),
          'last_exported_version': _metadata.currentVersion.toString(),
          'sync_status': 'ready',
        });
      }

      await refresh();
      if (!shared && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The update file is ready. Please send it now.'),
          ),
        );
      }
      return shared;
    } finally {
      _setWorking(false);
    }
  }

  Future<Loan?> getLoanById(String loanId) => _loanRepository.getLoanById(loanId);

  Future<List<Loan>> getLoansForBorrower(String borrowerId) =>
      _loanRepository.getLoansByBorrower(borrowerId);

  Future<List<Loan>> getOpenLoans() => _loanRepository.getOpenLoans();

  Future<List<Payment>> getPaymentsForLoan(String loanId) =>
      _paymentRepository.getPaymentsForLoan(loanId);

  Borrower? getBorrowerById(String borrowerId) {
    for (final borrower in _borrowers) {
      if (borrower.id == borrowerId) {
        return borrower;
      }
    }
    return null;
  }

  Future<bool> _runMutation(
    BuildContext context,
    Future<void> Function(int nextVersion) action,
  ) async {
    _setWorking(true);
    try {
      final nextVersion = _metadata.currentVersion + 1;
      await action(nextVersion);
      await _syncFileService.writeCurrentPackage();
      await refresh();
      _setWorking(false);
      if (context.mounted) {
        final shouldSend = await _showSendNowDialog(context);
        if (shouldSend && context.mounted) {
          await Navigator.of(context).pushNamed(AppRouter.sendUpdate);
        }
      }
      return true;
    } finally {
      if (_isWorking) {
        _setWorking(false);
      }
    }
  }

  Future<bool> _showSendNowDialog(BuildContext context) async {
    return (await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Send update now'),
              content: const Text(
                'A new update file is ready. Please send it to the other phone now.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Later'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Send now'),
                ),
              ],
            );
          },
        )) ??
        false;
  }

  Future<void> _handleIncomingFile(String filePath) async {
    await prepareImportFile(filePath, autoOpen: true);
  }

  Future<void> _setDeviceNameIfNeeded() async {
    final metadata = await _appStateRepository.loadMetadata();
    if (metadata.deviceName != 'This Phone') {
      return;
    }

    final plugin = DeviceInfoPlugin();
    try {
      final androidInfo = await plugin.androidInfo;
      final model = '${androidInfo.brand} ${androidInfo.model}'.trim();
      if (model.isNotEmpty) {
        await _appStateRepository.setValues({
          'device_name': model,
        });
      }
    } on Object {
      // Keep the fallback name if device info is unavailable.
    }
  }

  Future<void> _clearPendingImportState() async {
    final syncStatus = _metadata.syncStatus == SyncStatus.needsExport
        ? 'needs_export'
        : 'ready';
    await _appStateRepository.setValues({
      'pending_import_path': '',
      'pending_import_version': '',
      'sync_status': syncStatus,
    });
  }

  void _setWorking(bool value) {
    _isWorking = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    _deviceIntentService.dispose();
    super.dispose();
  }
}
