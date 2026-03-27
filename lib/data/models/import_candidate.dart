import 'sync_package.dart';

class ImportCandidate {
  const ImportCandidate({
    required this.filePath,
    this.package,
    required this.canImport,
    required this.message,
  });

  final String filePath;
  final SyncPackage? package;
  final bool canImport;
  final String message;
}

