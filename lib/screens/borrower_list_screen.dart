import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/primary_action_button.dart';
import '../state/app_controller.dart';

class BorrowerListScreen extends StatelessWidget {
  const BorrowerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        return AppShell(
          title: 'Borrowers',
          bottomBar: PrimaryActionButton(
            label: 'Add Borrower',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () {
              if (!controller.canEdit) {
                controller.ensureCanEdit(context);
                return;
              }
              Navigator.of(context).pushNamed(AppRoutes.borrowerForm);
            },
          ),
          child: controller.borrowers.isEmpty
              ? const _EmptyBorrowerState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final borrower = controller.borrowers[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        title: Text(
                          borrower.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            [
                              borrower.phone,
                              borrower.address,
                            ].whereType<String>().where((e) => e.isNotEmpty).join(' • '),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.borrowerDetail,
                            arguments: borrower.id,
                          );
                        },
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: controller.borrowers.length,
                ),
        );
      },
    );
  }
}

class _EmptyBorrowerState extends StatelessWidget {
  const _EmptyBorrowerState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No borrowers yet.\nAdd the first borrower below.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

