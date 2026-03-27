import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/formatters.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/primary_action_button.dart';
import '../state/app_controller.dart';

class ImportUpdateScreen extends StatelessWidget {
  const ImportUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final candidate = controller.importCandidate;

        return AppShell(
          title: 'Import Update',
          bottomBar: candidate?.canImport == true
              ? PrimaryActionButton(
                  label: 'Import Now',
                  icon: Icons.system_update_alt_rounded,
                  onPressed: () async {
                    final imported =
                        await controller.importPendingUpdate(context);
                    if (imported && context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                )
              : null,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (candidate == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose an update file to import.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        PrimaryActionButton(
                          label: 'Choose File',
                          icon: Icons.folder_open_rounded,
                          onPressed: () async {
                            await controller.pickImportFile(autoOpen: false);
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidate.message,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (candidate.package != null) ...[
                          _ImportRow(
                            label: 'Version',
                            value: candidate.package!.dataVersion.toString(),
                          ),
                          _ImportRow(
                            label: 'Sent from',
                            value: candidate.package!.exportedBy,
                          ),
                          _ImportRow(
                            label: 'Sent time',
                            value: Formatters.dateTime(
                              candidate.package!.exportedAt,
                            ),
                          ),
                          _ImportRow(
                            label: 'Borrowers',
                            value: candidate.package!.borrowers.length.toString(),
                          ),
                          _ImportRow(
                            label: 'Loans',
                            value: candidate.package!.loans.length.toString(),
                          ),
                          _ImportRow(
                            label: 'Payments',
                            value: candidate.package!.payments.length.toString(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryActionButton(
                  label: 'Choose Another File',
                  icon: Icons.folder_open_rounded,
                  onPressed: () async {
                    await controller.pickImportFile(autoOpen: false);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ImportRow extends StatelessWidget {
  const _ImportRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

