import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_router.dart';
import '../../../app/state/app_state_controller.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state_card.dart';

class BorrowersScreen extends StatelessWidget {
  const BorrowersScreen({
    super.key,
    required this.args,
  });

  final BorrowersScreenArgs args;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateController>(
      builder: (context, controller, _) {
        final title = args.selectionMode ? 'Choose Borrower' : 'Borrowers';

        return AppScaffold(
          title: title,
          bottomBar: ActionButton(
            label: 'Add Borrower',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () {
              if (!controller.ensureCanEdit(context)) {
                return;
              }
              Navigator.of(context).pushNamed(AppRouter.borrowerForm);
            },
          ),
          body: controller.borrowers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyStateCard(
                    message: 'No borrowers yet. Add the first borrower below.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.borrowers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final borrower = controller.borrowers[index];
                    final subtitle = [
                      borrower.phone,
                      borrower.address,
                    ].whereType<String>().where((value) => value.isNotEmpty).join(' | ');

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        title: Text(
                          borrower.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: subtitle.isEmpty
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                        trailing: Icon(
                          args.selectionMode
                              ? Icons.check_circle_outline_rounded
                              : Icons.chevron_right_rounded,
                        ),
                        onTap: () {
                          if (args.selectionMode) {
                            Navigator.of(context).pop(borrower.id);
                            return;
                          }

                          Navigator.of(context).pushNamed(
                            AppRouter.borrowerDetail,
                            arguments: borrower.id,
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
