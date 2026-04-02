import 'package:flutter/material.dart';

import '../core/utils/app_formatters.dart';
import '../data/models/app_metadata.dart';
import 'detail_row.dart';
import 'section_card.dart';

class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({
    super.key,
    required this.metadata,
  });

  final AppMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, borderColor) = switch (metadata.syncStatus) {
      SyncStatus.ready =>
        (const Color(0xFFD9F4E8), const Color(0xFF7EB998)),
      SyncStatus.needsImport =>
        (const Color(0xFFFFE2D7), const Color(0xFFD46E40)),
      SyncStatus.needsExport =>
        (const Color(0xFFFFF0CC), const Color(0xFFE3AD2A)),
    };

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              metadata.syncStatus.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          DetailRow(
            label: 'Current data version',
            value: metadata.currentVersion.toString(),
          ),
          DetailRow(
            label: 'This phone',
            value: metadata.deviceName,
          ),
          DetailRow(
            label: 'Last imported update',
            value: AppFormatters.dateTime(metadata.lastImportedAt),
          ),
          DetailRow(
            label: 'Last sent update',
            value: AppFormatters.dateTime(metadata.lastExportedAt),
          ),
        ],
      ),
    );
  }
}
