import 'package:flutter/material.dart';

import '../data/models/borrower.dart';
import '../data/models/loan.dart';
import '../screens/borrower_detail_screen.dart';
import '../screens/borrower_form_screen.dart';
import '../screens/borrower_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/import_update_screen.dart';
import '../screens/loan_detail_screen.dart';
import '../screens/loan_form_screen.dart';
import '../screens/payment_form_screen.dart';
import '../screens/send_update_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String borrowerList = '/borrowers';
  static const String borrowerDetail = '/borrower-detail';
  static const String borrowerForm = '/borrower-form';
  static const String loanDetail = '/loan-detail';
  static const String loanForm = '/loan-form';
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
      case borrowerList:
        return MaterialPageRoute<void>(
          builder: (_) => const BorrowerListScreen(),
          settings: settings,
        );
      case borrowerDetail:
        final borrowerId = settings.arguments! as String;
        return MaterialPageRoute<void>(
          builder: (_) => BorrowerDetailScreen(borrowerId: borrowerId),
          settings: settings,
        );
      case borrowerForm:
        final args = settings.arguments as BorrowerFormArgs?;
        return MaterialPageRoute<void>(
          builder: (_) => BorrowerFormScreen(args: args),
          settings: settings,
        );
      case loanDetail:
        final loanId = settings.arguments! as String;
        return MaterialPageRoute<void>(
          builder: (_) => LoanDetailScreen(loanId: loanId),
          settings: settings,
        );
      case loanForm:
        final args = settings.arguments! as LoanFormArgs;
        return MaterialPageRoute<void>(
          builder: (_) => LoanFormScreen(args: args),
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

class BorrowerFormArgs {
  const BorrowerFormArgs({this.borrower});

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

