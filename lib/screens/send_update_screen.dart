import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/formatters.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/primary_action_button.dart';
import '../data/models/app_metadata.dart';
import '../state/app_controller.dart';

class SendUpdateScreen extends StatelessWidget {
  const SendUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        final metadata = controller.metadata;
        final allowShare = metadata.currentVersion > 0 &&
            metadata.syncStatus != SyncStatus.needsImport;

        return AppShell(
          title: 'Send Update',
          bottomBar: PrimaryActionButton(
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metadata.currentVersion <= 0
                            ? 'No records yet.'
                            : metadata.syncStatus == SyncStatus.needsImport
                                ? 'Import the newer update before sending anything from this phone.'
                            : 'Send the latest file to the other phone now.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _SendRow(
                        label: 'Current version',
                        value: metadata.currentVersion.toString(),
                      ),
                      _SendRow(
                        label: 'Last send time',
                        value: Formatters.dateTime(metadata.lastExportedAt),
                      ),
                      _SendRow(
                        label: 'This phone',
                        value: metadata.deviceName,
                      ),
                      _SendRow(
                        label: 'File name',
                        value: 'moneyloan_update.mloan',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SendRow extends StatelessWidget {
  const _SendRow({
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
