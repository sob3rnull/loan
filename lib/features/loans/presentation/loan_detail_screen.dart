import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_router.dart';
import '../../../app/state/app_state_controller.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/payment.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/detail_row.dart';
import '../../../widgets/empty_state_card.dart';
import '../../../widgets/section_card.dart';

class LoanDetailScreen extends StatelessWidget {
  const LoanDetailScreen({
    super.key,
    required this.loanId,
  });

  final String loanId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateController>(
      builder: (context, controller, _) {
        return FutureBuilder<Loan?>(
          key: ValueKey('loan-$loanId-${controller.metadata.currentVersion}'),
          future: controller.getLoanById(loanId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final loan = snapshot.data;
            if (loan == null) {
              return const Scaffold(
                body: Center(child: Text('Loan not found.')),
              );
            }

            final borrower = controller.getBorrowerById(loan.borrowerId);

            return AppScaffold(
              title: 'Loan Details',
              bottomBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionButton(
                    label: 'Add Payment',
                    icon: Icons.payments_rounded,
                    onPressed: () {
                      if (!controller.ensureCanEdit(context)) {
                        return;
                      }
                      Navigator.of(context).pushNamed(
                        AppRouter.paymentForm,
                        arguments: loan.id,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (!controller.ensureCanEdit(context)) {
                        return;
                      }
                      Navigator.of(context).pushNamed(
                        AppRouter.loanForm,
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
                  OutlinedButton.icon(
                    onPressed: () {
                      if (!controller.ensureCanEdit(context)) {
                        return;
                      }
                      _deleteLoan(context, loan.id);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete Loan'),
                  ),
                ],
              ),
              body: FutureBuilder<List<Payment>>(
                future: controller.getPaymentsForLoan(loan.id),
                builder: (context, paymentSnapshot) {
                  final payments = paymentSnapshot.data ?? <Payment>[];
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DetailRow(
                              label: 'Borrower',
                              value: borrower?.name ?? '-',
                            ),
                            DetailRow(
                              label: 'Principal',
                              value: AppFormatters.money(loan.principal),
                            ),
                            DetailRow(
                              label: 'Interest',
                              value: loan.interestType == 'percentage'
                                  ? '${loan.interestValue}%'
                                  : AppFormatters.money(loan.interestValue),
                            ),
                            DetailRow(
                              label: 'Total repayable',
                              value: AppFormatters.money(loan.totalRepayable),
                            ),
                            DetailRow(
                              label: 'Amount paid',
                              value: AppFormatters.money(loan.amountPaid),
                            ),
                            DetailRow(
                              label: 'Remaining amount',
                              value: AppFormatters.money(loan.remainingAmount),
                            ),
                            DetailRow(
                              label: 'Start date',
                              value: AppFormatters.shortDate(loan.startDate),
                            ),
                            DetailRow(
                              label: 'Due date',
                              value: AppFormatters.shortDate(loan.dueDate),
                            ),
                            DetailRow(
                              label: 'Status',
                              value: loan.status,
                            ),
                            DetailRow(
                              label: 'Note',
                              value: loan.note?.isNotEmpty == true ? loan.note! : '-',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Payments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (paymentSnapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (payments.isEmpty)
                        const EmptyStateCard(
                          message: 'No payments have been added for this loan yet.',
                        )
                      else
                        ...payments.map(
                          (payment) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(18),
                                title: Text(
                                  AppFormatters.money(payment.amount),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Date ${AppFormatters.shortDate(payment.paymentDate)}\n'
                                    'Note ${payment.note?.isNotEmpty == true ? payment.note! : '-'}',
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

  Future<void> _deleteLoan(BuildContext context, String loanId) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete loan'),
              content: const Text(
                'This will delete the loan and all payments on that loan.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete || !context.mounted) {
      return;
    }

    final controller = context.read<AppStateController>();
    final deleted = await controller.deleteLoanAndPromptShare(
      context,
      loanId: loanId,
    );

    if (deleted && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
