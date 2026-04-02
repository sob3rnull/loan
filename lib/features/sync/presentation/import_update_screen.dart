import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/state/app_state_controller.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/detail_row.dart';
import '../../../widgets/section_card.dart';

class ImportUpdateScreen extends StatelessWidget {
  const ImportUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateController>(
      builder: (context, controller, _) {
        final candidate = controller.importCandidate;

        return AppScaffold(
          title: 'Import Update',
          bottomBar: candidate?.canImport == true
              ? ActionButton(
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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                child: Text(
                  'Before importing, the app automatically makes a backup of current data.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              if (candidate == null)
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a .mloan update file to import.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ActionButton(
                        label: 'Choose File',
                        icon: Icons.folder_open_rounded,
                        onPressed: () async {
                          await controller.pickImportFile(autoOpen: false);
                        },
                      ),
                    ],
                  ),
                )
              else ...[
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.message,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      if (candidate.package != null) ...[
                        DetailRow(
                          label: 'Incoming version',
                          value: candidate.package!.dataVersion.toString(),
                        ),
                        DetailRow(
                          label: 'Sent from',
                          value: candidate.package!.exportedBy,
                        ),
                        DetailRow(
                          label: 'Sent time',
                          value:
                              AppFormatters.dateTime(candidate.package!.exportedAt),
                        ),
                        DetailRow(
                          label: 'Borrowers',
                          value: candidate.package!.borrowers.length.toString(),
                        ),
                        DetailRow(
                          label: 'Loans',
                          value: candidate.package!.loans.length.toString(),
                        ),
                        DetailRow(
                          label: 'Payments',
                          value: candidate.package!.payments.length.toString(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ActionButton(
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
