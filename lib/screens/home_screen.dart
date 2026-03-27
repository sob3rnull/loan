import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/primary_action_button.dart';
import '../core/widgets/summary_tile.dart';
import '../data/models/app_metadata.dart';
import '../state/app_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final metadata = controller.metadata;
        final summary = controller.summary;

        return AppShell(
          title: 'Money Loan',
          actions: [
            IconButton(
              onPressed: () {
                controller.refresh();
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(metadata: metadata),
              const SizedBox(height: 16),
              Text(
                'Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SummaryTile(
                    label: 'Active loans',
                    value: summary.activeLoansCount.toString(),
                  ),
                  SummaryTile(
                    label: 'Total principal',
                    value: Formatters.money(summary.totalPrincipal),
                  ),
                  SummaryTile(
                    label: 'Total collected',
                    value: Formatters.money(summary.totalCollected),
                  ),
                  SummaryTile(
                    label: 'Total remaining',
                    value: Formatters.money(summary.totalRemaining),
                  ),
                  SummaryTile(
                    label: 'Overdue loans',
                    value: summary.overdueLoansCount.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryActionButton(
                label: 'View Records',
                icon: Icons.people_alt_rounded,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.borrowerList);
                },
              ),
              const SizedBox(height: 12),
              PrimaryActionButton(
                label: 'Import Received Update',
                icon: Icons.download_rounded,
                onPressed: () async {
                  if (controller.importCandidate != null ||
                      metadata.pendingImportPath != null) {
                    Navigator.of(context).pushNamed(AppRoutes.importUpdate);
                    return;
                  }

                  await controller.pickImportFile();
                  if (context.mounted && controller.importCandidate != null) {
                    Navigator.of(context).pushNamed(AppRoutes.importUpdate);
                  }
                },
              ),
              const SizedBox(height: 12),
              PrimaryActionButton(
                label: 'Save & Send Update',
                icon: Icons.send_rounded,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.sendUpdate);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.metadata});

  final AppMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (metadata.syncStatus) {
      SyncStatus.ready => const Color(0xFFD9F4E8),
      SyncStatus.needsImport => const Color(0xFFFFE1D6),
      SyncStatus.needsExport => const Color(0xFFFFF0CC),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                metadata.syncStatus.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'This phone',
              value: metadata.deviceName,
            ),
            _InfoRow(
              label: 'Current version',
              value: metadata.currentVersion.toString(),
            ),
            _InfoRow(
              label: 'Last import',
              value: Formatters.dateTime(metadata.lastImportedAt),
            ),
            _InfoRow(
              label: 'Last send',
              value: Formatters.dateTime(metadata.lastExportedAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
