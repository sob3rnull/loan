import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_router.dart';
import '../../../app/state/app_state_controller.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/app_metadata.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/sync_status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final summary = controller.summary;

        return AppScaffold(
          title: 'Money Loan Sync',
          actions: [
            IconButton(
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SyncStatusCard(metadata: controller.metadata),
              const SizedBox(height: 16),
              Text(
                'Summary Dashboard',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 380 ? 1 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      StatCard(
                        label: 'Current data version',
                        value: controller.metadata.currentVersion.toString(),
                      ),
                      StatCard(
                        label: 'Sync status',
                        value: controller.metadata.syncStatus.label,
                      ),
                      StatCard(
                        label: 'Total principal',
                        value: AppFormatters.money(summary.totalPrincipal),
                      ),
                      StatCard(
                        label: 'Total collected',
                        value: AppFormatters.money(summary.totalCollected),
                      ),
                      StatCard(
                        label: 'Total remaining',
                        value: AppFormatters.money(summary.totalRemaining),
                      ),
                      StatCard(
                        label: 'Active loans count',
                        value: summary.activeLoansCount.toString(),
                      ),
                      StatCard(
                        label: 'Overdue count',
                        value: summary.overdueLoansCount.toString(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              ActionButton(
                label: 'View Records',
                icon: Icons.people_alt_rounded,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.borrowers);
                },
              ),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Add Loan',
                icon: Icons.account_balance_wallet_rounded,
                onPressed: () => _handleAddLoan(context),
              ),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Add Payment',
                icon: Icons.payments_rounded,
                onPressed: () => _handleAddPayment(context),
              ),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Import Received Update',
                icon: Icons.download_rounded,
                onPressed: () => _handleImport(context),
              ),
              const SizedBox(height: 12),
              ActionButton(
                label: 'Save & Send Update',
                icon: Icons.send_rounded,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.sendUpdate);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAddLoan(BuildContext context) async {
    final controller = context.read<AppStateController>();
    if (!controller.ensureCanEdit(context)) {
      return;
    }

    if (controller.borrowers.isEmpty) {
      final shouldAddBorrower = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Add borrower first'),
                content: const Text(
                  'Please add a borrower before creating a loan.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Add Borrower'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (shouldAddBorrower && context.mounted) {
        await Navigator.of(context).pushNamed(AppRouter.borrowerForm);
      }
      return;
    }

    final borrowerId = await Navigator.of(context).pushNamed<String>(
      AppRouter.borrowers,
      arguments: const BorrowersScreenArgs(selectionMode: true),
    );

    if (borrowerId != null && context.mounted) {
      await Navigator.of(context).pushNamed(
        AppRouter.loanForm,
        arguments: LoanFormArgs(borrowerId: borrowerId),
      );
    }
  }

  Future<void> _handleAddPayment(BuildContext context) async {
    final controller = context.read<AppStateController>();
    if (!controller.ensureCanEdit(context)) {
      return;
    }

    final loanId = await Navigator.of(context).pushNamed<String>(
      AppRouter.loanPicker,
    );

    if (loanId != null && context.mounted) {
      await Navigator.of(context).pushNamed(
        AppRouter.paymentForm,
        arguments: loanId,
      );
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final controller = context.read<AppStateController>();
    if (controller.importCandidate != null || controller.metadata.hasPendingImport) {
      await Navigator.of(context).pushNamed(AppRouter.importUpdate);
      return;
    }

    await controller.pickImportFile();
    if (context.mounted && controller.importCandidate != null) {
      await Navigator.of(context).pushNamed(AppRouter.importUpdate);
    }
  }
}
