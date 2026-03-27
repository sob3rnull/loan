import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/app_routes.dart';
import 'core/theme.dart';
import 'data/local/database_helper.dart';
import 'data/repositories/app_state_repository.dart';
import 'data/repositories/borrower_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/loan_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/seed/sample_seed_service.dart';
import 'services/device_intent_service.dart';
import 'services/export_import_service.dart';
import 'services/share_service.dart';
import 'state/app_controller.dart';

class MoneyLoanApp extends StatefulWidget {
  const MoneyLoanApp({super.key});

  @override
  State<MoneyLoanApp> createState() => _MoneyLoanAppState();
}

class _MoneyLoanAppState extends State<MoneyLoanApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppController _controller;

  @override
  void initState() {
    super.initState();

    final databaseHelper = DatabaseHelper.instance;
    final appStateRepository = AppStateRepository(databaseHelper);
    final borrowerRepository = BorrowerRepository(databaseHelper);
    final loanRepository = LoanRepository(databaseHelper);
    final paymentRepository = PaymentRepository(databaseHelper);
    final dashboardRepository = DashboardRepository(databaseHelper);
    final exportImportService = ExportImportService(
      databaseHelper: databaseHelper,
      appStateRepository: appStateRepository,
      borrowerRepository: borrowerRepository,
      loanRepository: loanRepository,
      paymentRepository: paymentRepository,
    );

    _controller = AppController(
      appStateRepository: appStateRepository,
      borrowerRepository: borrowerRepository,
      loanRepository: loanRepository,
      paymentRepository: paymentRepository,
      dashboardRepository: dashboardRepository,
      exportImportService: exportImportService,
      shareService: ShareService(),
      deviceIntentService: DeviceIntentService(AppConfig.intentChannelName),
      sampleSeedService: SampleSeedService(
        databaseHelper: databaseHelper,
        appStateRepository: appStateRepository,
        borrowerRepository: borrowerRepository,
        loanRepository: loanRepository,
        paymentRepository: paymentRepository,
        exportImportService: exportImportService,
      ),
    );

    _controller.addListener(_handleControllerEvents);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerEvents);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerEvents() {
    if (!_controller.shouldAutoOpenImportScreen) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _controller.consumeImportAutoOpenFlag();
    navigator.pushNamed(AppRoutes.importUpdate);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppController>.value(
      value: _controller,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: buildAppTheme(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: AppRoutes.home,
      ),
    );
  }
}

