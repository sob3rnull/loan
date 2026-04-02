import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/state/app_state_controller.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/loan.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state_card.dart';

class LoanPickerScreen extends StatelessWidget {
  const LoanPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateController>(
      builder: (context, controller, _) {
        return AppScaffold(
          title: 'Choose Loan',
          body: FutureBuilder<List<Loan>>(
            future: controller.getOpenLoans(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final loans = snapshot.data ?? <Loan>[];
              if (loans.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyStateCard(
                    message: 'There are no active loans to pay right now.',
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: loans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final loan = loans[index];
                  final borrower = controller.getBorrowerById(loan.borrowerId);

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      title: Text(
                        borrower?.name ?? 'Unknown borrower',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Remaining ${AppFormatters.money(loan.remainingAmount)}\n'
                          'Due ${AppFormatters.shortDate(loan.dueDate)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).pop(loan.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
