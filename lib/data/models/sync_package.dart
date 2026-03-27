import 'borrower.dart';
import 'loan.dart';
import 'payment.dart';

class SyncPackage {
  const SyncPackage({
    required this.appVersion,
    required this.dataVersion,
    required this.exportedAt,
    required this.exportedBy,
    required this.borrowers,
    required this.loans,
    required this.payments,
  });

  final int appVersion;
  final int dataVersion;
  final String exportedAt;
  final String exportedBy;
  final List<Borrower> borrowers;
  final List<Loan> loans;
  final List<Payment> payments;

  Map<String, Object?> toJson() {
    return {
      'appVersion': appVersion,
      'dataVersion': dataVersion,
      'exportedAt': exportedAt,
      'exportedBy': exportedBy,
      'borrowers': borrowers.map((item) => item.toJson()).toList(),
      'loans': loans.map((item) => item.toJson()).toList(),
      'payments': payments.map((item) => item.toJson()).toList(),
    };
  }

  factory SyncPackage.fromJson(Map<String, dynamic> json) {
    final borrowers = json['borrowers'];
    final loans = json['loans'];
    final payments = json['payments'];

    if (borrowers is! List || loans is! List || payments is! List) {
      throw const FormatException('Missing list data.');
    }

    return SyncPackage(
      appVersion: json['appVersion'] as int,
      dataVersion: json['dataVersion'] as int,
      exportedAt: json['exportedAt'] as String,
      exportedBy: json['exportedBy'] as String? ?? 'Unknown Phone',
      borrowers: borrowers
          .map((item) => Borrower.fromJson(item as Map<String, dynamic>))
          .toList(),
      loans: loans
          .map((item) => Loan.fromJson(item as Map<String, dynamic>))
          .toList(),
      payments: payments
          .map((item) => Payment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
