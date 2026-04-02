import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../core/theme/app_theme.dart';
import '../data/local/database_helper.dart';
import '../data/repositories/app_state_repository.dart';
import '../data/repositories/borrower_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/loan_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/services/device_intent_service.dart';
import '../data/services/share_service.dart';
import '../data/services/sync_file_service.dart';
import 'app_router.dart';
import 'state/app_state_controller.dart';

class MoneyLoanSyncApp extends StatefulWidget {
  const MoneyLoanSyncApp({super.key});

  @override
  State<MoneyLoanSyncApp> createState() => _MoneyLoanSyncAppState();
}

class _MoneyLoanSyncAppState extends State<MoneyLoanSyncApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppStateController _controller;

  @override
  void initState() {
    super.initState();

    final databaseHelper = DatabaseHelper.instance;
    final appStateRepository = AppStateRepository(databaseHelper);
    final borrowerRepository = BorrowerRepository(databaseHelper);
    final loanRepository = LoanRepository(databaseHelper);
    final paymentRepository = PaymentRepository(databaseHelper);
    final dashboardRepository = DashboardRepository(databaseHelper);
    final syncFileService = SyncFileService(
      databaseHelper: databaseHelper,
      appStateRepository: appStateRepository,
      borrowerRepository: borrowerRepository,
      loanRepository: loanRepository,
      paymentRepository: paymentRepository,
    );

    _controller = AppStateController(
      appStateRepository: appStateRepository,
      borrowerRepository: borrowerRepository,
      loanRepository: loanRepository,
      paymentRepository: paymentRepository,
      dashboardRepository: dashboardRepository,
      syncFileService: syncFileService,
      shareService: ShareService(),
      deviceIntentService: DeviceIntentService(AppConfig.intentChannelName),
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
    navigator.pushNamed(AppRouter.importUpdate);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppStateController>.value(
      value: _controller,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: buildAppTheme(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.home,
      ),
    );
  }
}
