import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_shell.dart';
import '../data/models/loan.dart';
import '../state/app_controller.dart';

class BorrowerDetailScreen extends StatelessWidget {
  const BorrowerDetailScreen({
    super.key,
    required this.borrowerId,
  });

  final String borrowerId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final borrower = controller.getBorrowerById(borrowerId);
        if (borrower == null) {
          return const Scaffold(
            body: Center(child: Text('Borrower not found')),
          );
        }

        return AppShell(
          title: borrower.name,
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
                    AppRoutes.borrowerForm,
                    arguments: BorrowerFormArgs(borrower: borrower),
                  );
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Borrower'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  if (!controller.canEdit) {
                    controller.ensureCanEdit(context);
                    return;
                  }
                  Navigator.of(context).pushNamed(
                    AppRoutes.loanForm,
                    arguments: LoanFormArgs(borrowerId: borrower.id),
                  );
                },
                icon: const Icon(Icons.account_balance_wallet_rounded),
                label: const Text('Add Loan'),
              ),
            ],
          ),
          child: FutureBuilder<List<Loan>>(
            key: ValueKey('borrower-$borrowerId-${controller.metadata.currentVersion}'),
            future: controller.getLoansForBorrower(borrowerId),
            builder: (context, snapshot) {
              final loans = snapshot.data ?? <Loan>[];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(label: 'Phone', value: borrower.phone ?? '-'),
                          _DetailRow(
                            label: 'Address',
                            value: borrower.address ?? '-',
                          ),
                          _DetailRow(label: 'Note', value: borrower.note ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loans',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (loans.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'No loans yet.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  else
                    ...loans.map(
                      (loan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(18),
                            title: Text(
                              'Remaining ${Formatters.money(loan.remainingAmount)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Total ${Formatters.money(loan.totalRepayable)}\n'
                                'Paid ${Formatters.money(loan.amountPaid)}\n'
                                'Due ${Formatters.shortDate(loan.dueDate)}\n'
                                'Status ${loan.status}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.loanDetail,
                                arguments: loan.id,
                              );
                            },
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
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
