import 'package:sqflite/sqflite.dart';

import '../local/database_helper.dart';
import '../models/app_metadata.dart';

class AppStateRepository {
  AppStateRepository(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<AppMetadata> loadMetadata() async {
    final db = await _databaseHelper.database;
    final rows = await db.query('app_state');
    final map = <String, String>{
      for (final row in rows)
        row['key'] as String: (row['value'] as String?) ?? '',
    };

    return AppMetadata(
      currentVersion: int.tryParse(map['current_version'] ?? '') ?? 0,
      lastImportedAt: _emptyToNull(map['last_imported_at']),
      lastExportedAt: _emptyToNull(map['last_exported_at']),
      lastExportedVersion: int.tryParse(map['last_exported_version'] ?? ''),
      syncStatus: syncStatusFromStorage(map['sync_status']),
      deviceName: map['device_name']?.isNotEmpty == true
          ? map['device_name']!
          : 'This Phone',
      pendingImportPath: _emptyToNull(map['pending_import_path']),
      pendingImportVersion: int.tryParse(map['pending_import_version'] ?? ''),
    );
  }

  Future<void> setValues(Map<String, String?> values) async {
    final db = await _databaseHelper.database;
    await setValuesOn(db, values);
  }

  Future<void> setValuesOn(
    DatabaseExecutor executor,
    Map<String, String?> values,
  ) async {
    for (final entry in values.entries) {
      await executor.insert(
        'app_state',
        {
          'key': entry.key,
          'value': entry.value ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  String? _emptyToNull(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}

