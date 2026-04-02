import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/state/app_state_controller.dart';
import '../../../core/app_config.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/app_metadata.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/detail_row.dart';
import '../../../widgets/section_card.dart';

class SendUpdateScreen extends StatelessWidget {
  const SendUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateController>(
      builder: (context, controller, _) {
        final metadata = controller.metadata;
        final allowShare =
            metadata.currentVersion > 0 && metadata.syncStatus != SyncStatus.needsImport;

        return AppScaffold(
          title: 'Save & Send Update',
          bottomBar: ActionButton(
            label: 'Share Update Now',
            icon: Icons.share_rounded,
            onPressed: !allowShare
                ? null
                : () async {
                    final shared = await controller.shareLatestUpdate(context);
                    if (shared && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                child: Text(
                  metadata.currentVersion <= 0
                      ? 'No records have been saved yet.'
                      : metadata.syncStatus == SyncStatus.needsImport
                          ? 'Import the newer update first before sending anything from this phone.'
                          : metadata.syncStatus == SyncStatus.needsExport
                              ? 'Please send the newest update file now. Editing stays locked until it is sent.'
                              : 'You can send the latest update file from this phone now.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailRow(
                      label: 'Current version',
                      value: metadata.currentVersion.toString(),
                    ),
                    DetailRow(
                      label: 'Sync status',
                      value: metadata.syncStatus.label,
                    ),
                    DetailRow(
                      label: 'This phone',
                      value: metadata.deviceName,
                    ),
                    DetailRow(
                      label: 'Last sent',
                      value: AppFormatters.dateTime(metadata.lastExportedAt),
                    ),
                    DetailRow(
                      label: 'File name',
                      value: AppConfig.syncFileName,
                    ),
                    DetailRow(
                      label: 'File type',
                      value: '.mloan (JSON inside)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
