import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_router.dart';
import '../../../app/state/app_state_controller.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/loan.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/detail_row.dart';
import '../../../widgets/empty_state_card.dart';
import '../../../widgets/section_card.dart';

class BorrowerDetailScreen extends StatelessWidget {
  const BorrowerDetailScreen({
    super.key,
    required this.borrowerId,
  });

  final String borrowerId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateController>(
      builder: (context, controller, _) {
        final borrower = controller.getBorrowerById(borrowerId);
        if (borrower == null) {
          return const Scaffold(
            body: Center(child: Text('Borrower not found.')),
          );
        }

        return AppScaffold(
          title: borrower.name,
          bottomBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionButton(
                label: 'Add Loan',
                icon: Icons.account_balance_wallet_rounded,
                onPressed: () {
                  if (!controller.ensureCanEdit(context)) {
                    return;
                  }
                  Navigator.of(context).pushNamed(
                    AppRouter.loanForm,
                    arguments: LoanFormArgs(borrowerId: borrower.id),
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
                    AppRouter.borrowerForm,
                    arguments: BorrowerFormArgs(borrower: borrower),
                  );
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Borrower'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  if (!controller.ensureCanEdit(context)) {
                    return;
                  }
                  _deleteBorrower(context, borrower.id);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete Borrower'),
              ),
            ],
          ),
          body: FutureBuilder<List<Loan>>(
            key: ValueKey('borrower-$borrowerId-${controller.metadata.currentVersion}'),
            future: controller.getLoansForBorrower(borrowerId),
            builder: (context, snapshot) {
              final loans = snapshot.data ?? <Loan>[];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DetailRow(
                          label: 'Phone',
                          value: borrower.phone?.isNotEmpty == true
                              ? borrower.phone!
                              : '-',
                        ),
                        DetailRow(
                          label: 'Address',
                          value: borrower.address?.isNotEmpty == true
                              ? borrower.address!
                              : '-',
                        ),
                        DetailRow(
                          label: 'Note',
                          value:
                              borrower.note?.isNotEmpty == true ? borrower.note! : '-',
                        ),
                      ],
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
                    const EmptyStateCard(
                      message: 'No loans yet for this borrower.',
                    )
                  else
                    ...loans.map(
                      (loan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(18),
                            title: Text(
                              'Remaining ${AppFormatters.money(loan.remainingAmount)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Total ${AppFormatters.money(loan.totalRepayable)}\n'
                                'Paid ${AppFormatters.money(loan.amountPaid)}\n'
                                'Due ${AppFormatters.shortDate(loan.dueDate)}\n'
                                'Status ${loan.status}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.loanDetail,
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

  Future<void> _deleteBorrower(BuildContext context, String borrowerId) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete borrower'),
              content: const Text(
                'This will delete the borrower, all loans, and all payments for that borrower.',
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
    final deleted = await controller.deleteBorrowerAndPromptShare(
      context,
      borrowerId: borrowerId,
    );

    if (deleted && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
