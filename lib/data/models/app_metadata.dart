enum SyncStatus {
  ready,
  needsImport,
  needsExport,
}

extension SyncStatusX on SyncStatus {
  String get storageValue {
    switch (this) {
      case SyncStatus.ready:
        return 'ready';
      case SyncStatus.needsImport:
        return 'needs_import';
      case SyncStatus.needsExport:
        return 'needs_export';
    }
  }

  String get label {
    switch (this) {
      case SyncStatus.ready:
        return 'Ready';
      case SyncStatus.needsImport:
        return 'Need to import latest update';
      case SyncStatus.needsExport:
        return 'Need to send latest update';
    }
  }

  String get userMessage {
    switch (this) {
      case SyncStatus.ready:
        return 'Everything is up to date.';
      case SyncStatus.needsImport:
        return 'Import latest update first';
      case SyncStatus.needsExport:
        return 'Send latest update now';
    }
  }
}

SyncStatus syncStatusFromStorage(String? value) {
  switch (value) {
    case 'needs_import':
      return SyncStatus.needsImport;
    case 'needs_export':
      return SyncStatus.needsExport;
    case 'ready':
    default:
      return SyncStatus.ready;
  }
}

class AppMetadata {
  const AppMetadata({
    required this.currentVersion,
    this.lastImportedAt,
    this.lastExportedAt,
    this.lastExportedVersion,
    required this.syncStatus,
    required this.deviceName,
    this.pendingImportPath,
    this.pendingImportVersion,
  });

  final int currentVersion;
  final String? lastImportedAt;
  final String? lastExportedAt;
  final int? lastExportedVersion;
  final SyncStatus syncStatus;
  final String deviceName;
  final String? pendingImportPath;
  final int? pendingImportVersion;

  factory AppMetadata.initial() {
    return const AppMetadata(
      currentVersion: 0,
      syncStatus: SyncStatus.ready,
      deviceName: 'This Phone',
    );
  }
}

