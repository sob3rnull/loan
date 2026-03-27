import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_shell.dart';
import '../data/models/loan.dart';
import '../data/models/payment.dart';
import '../state/app_controller.dart';

class LoanDetailScreen extends StatelessWidget {
  const LoanDetailScreen({
    super.key,
    required this.loanId,
  });

  final String loanId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        return FutureBuilder<Loan?>(
          key: ValueKey('loan-$loanId-${controller.metadata.currentVersion}'),
          future: controller.getLoanById(loanId),
          builder: (context, snapshot) {
            final loan = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (loan == null) {
              return const Scaffold(
                body: Center(child: Text('Loan not found')),
              );
            }

            final borrower = controller.getBorrowerById(loan.borrowerId);

            return AppShell(
              title: 'Loan Detail',
              bottomBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      if (!controller.canEdit) {
                        controller.ensureCanEdit(context);
                        return;
                      }
                      Navigator.of(context).pushNamed(
                        AppRoutes.loanForm,
                        arguments: LoanFormArgs(
                          borrowerId: loan.borrowerId,
                          loan: loan,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Loan'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      if (!controller.canEdit) {
                        controller.ensureCanEdit(context);
                        return;
                      }
                      Navigator.of(context).pushNamed(
                        AppRoutes.paymentForm,
                        arguments: loan.id,
                      );
                    },
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text('Add Payment'),
                  ),
                ],
              ),
              child: FutureBuilder<List<Payment>>(
                future: controller.getPaymentsForLoan(loan.id),
                builder: (context, paymentSnapshot) {
                  final payments = paymentSnapshot.data ?? <Payment>[];
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LoanInfoRow(
                                label: 'Borrower',
                                value: borrower?.name ?? '-',
                              ),
                              _LoanInfoRow(
                                label: 'Principal',
                                value: Formatters.money(loan.principal),
                              ),
                              _LoanInfoRow(
                                label: 'Interest',
                                value: loan.interestType == 'percentage'
                                    ? '${loan.interestValue}%'
                                    : Formatters.money(loan.interestValue),
                              ),
                              _LoanInfoRow(
                                label: 'Total repayable',
                                value: Formatters.money(loan.totalRepayable),
                              ),
                              _LoanInfoRow(
                                label: 'Amount paid',
                                value: Formatters.money(loan.amountPaid),
                              ),
                              _LoanInfoRow(
                                label: 'Remaining',
                                value: Formatters.money(loan.remainingAmount),
                              ),
                              _LoanInfoRow(
                                label: 'Start date',
                                value: Formatters.shortDate(loan.startDate),
                              ),
                              _LoanInfoRow(
                                label: 'Due date',
                                value: Formatters.shortDate(loan.dueDate),
                              ),
                              _LoanInfoRow(label: 'Status', value: loan.status),
                              _LoanInfoRow(label: 'Note', value: loan.note ?? '-'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Payments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (paymentSnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (payments.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              'No payments yet.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        )
                      else
                        ...payments.map(
                          (payment) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(18),
                                title: Text(
                                  Formatters.money(payment.amount),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Date ${Formatters.shortDate(payment.paymentDate)}\n'
                                    'Note ${payment.note ?? '-'}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _LoanInfoRow extends StatelessWidget {
  const _LoanInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
