import 'package:flutter/material.dart';

import '../data/models/borrower.dart';
import '../data/models/loan.dart';
import '../features/borrowers/presentation/borrower_detail_screen.dart';
import '../features/borrowers/presentation/borrower_form_screen.dart';
import '../features/borrowers/presentation/borrowers_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/loans/presentation/loan_detail_screen.dart';
import '../features/loans/presentation/loan_form_screen.dart';
import '../features/loans/presentation/loan_picker_screen.dart';
import '../features/payments/presentation/payment_form_screen.dart';
import '../features/sync/presentation/import_update_screen.dart';
import '../features/sync/presentation/send_update_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String borrowers = '/borrowers';
  static const String borrowerForm = '/borrower-form';
  static const String borrowerDetail = '/borrower-detail';
  static const String loanForm = '/loan-form';
  static const String loanDetail = '/loan-detail';
  static const String loanPicker = '/loan-picker';
  static const String paymentForm = '/payment-form';
  static const String importUpdate = '/import-update';
  static const String sendUpdate = '/send-update';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case borrowers:
        final args = settings.arguments as BorrowersScreenArgs?;
        return MaterialPageRoute<dynamic>(
          builder: (_) => BorrowersScreen(
            args: args ?? const BorrowersScreenArgs(),
          ),
          settings: settings,
        );
      case borrowerForm:
        final args = settings.arguments as BorrowerFormArgs?;
        return MaterialPageRoute<void>(
          builder: (_) => BorrowerFormScreen(args: args),
          settings: settings,
        );
      case borrowerDetail:
        final borrowerId = settings.arguments! as String;
        return MaterialPageRoute<void>(
          builder: (_) => BorrowerDetailScreen(borrowerId: borrowerId),
          settings: settings,
        );
      case loanForm:
        final args = settings.arguments! as LoanFormArgs;
        return MaterialPageRoute<void>(
          builder: (_) => LoanFormScreen(args: args),
          settings: settings,
        );
      case loanDetail:
        final loanId = settings.arguments! as String;
        return MaterialPageRoute<void>(
          builder: (_) => LoanDetailScreen(loanId: loanId),
          settings: settings,
        );
      case loanPicker:
        return MaterialPageRoute<String>(
          builder: (_) => const LoanPickerScreen(),
          settings: settings,
        );
      case paymentForm:
        final loanId = settings.arguments! as String;
        return MaterialPageRoute<void>(
          builder: (_) => PaymentFormScreen(loanId: loanId),
          settings: settings,
        );
      case importUpdate:
        return MaterialPageRoute<void>(
          builder: (_) => const ImportUpdateScreen(),
          settings: settings,
        );
      case sendUpdate:
        return MaterialPageRoute<void>(
          builder: (_) => const SendUpdateScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
    }
  }
}

class BorrowersScreenArgs {
  const BorrowersScreenArgs({
    this.selectionMode = false,
  });

  final bool selectionMode;
}

class BorrowerFormArgs {
  const BorrowerFormArgs({
    this.borrower,
  });

  final Borrower? borrower;
}

class LoanFormArgs {
  const LoanFormArgs({
    required this.borrowerId,
    this.loan,
  });

  final String borrowerId;
  final Loan? loan;
}
