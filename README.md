# Money Loan Sync

Money Loan Sync is an offline-first Flutter Android app for two older non-technical users who track borrowers, loans, and payments on separate phones and manually exchange update files over Telegram, Viber, or file apps.

The app uses:

- SQLite local storage only
- Manual `.mloan` export and import
- JSON inside the sync file
- Android intent handling for opening shared `.mloan` files
- Large-text, simple UI for elderly users

## Active folder structure

```text
lib/
  main.dart
  app/
    app.dart
    app_router.dart
    state/
      app_state_controller.dart
  core/
    app_config.dart
    theme/
      app_theme.dart
    utils/
      app_formatters.dart
      loan_math.dart
  data/
    local/
      database_helper.dart
    models/
      app_metadata.dart
      borrower.dart
      dashboard_summary.dart
      import_candidate.dart
      loan.dart
      payment.dart
      sync_package.dart
    repositories/
      app_state_repository.dart
      borrower_repository.dart
      dashboard_repository.dart
      loan_repository.dart
      payment_repository.dart
    services/
      device_intent_service.dart
      share_service.dart
      sync_file_service.dart
  features/
    home/presentation/
      home_screen.dart
    borrowers/presentation/
      borrowers_screen.dart
      borrower_form_screen.dart
      borrower_detail_screen.dart
    loans/presentation/
      loan_form_screen.dart
      loan_detail_screen.dart
      loan_picker_screen.dart
    payments/presentation/
      payment_form_screen.dart
    sync/presentation/
      import_update_screen.dart
      send_update_screen.dart
  widgets/
    action_button.dart
    app_scaffold.dart
    detail_row.dart
    empty_state_card.dart
    section_card.dart
    stat_card.dart
    sync_status_card.dart

android/app/src/main/
  AndroidManifest.xml
  kotlin/com/example/moneyloan/MainActivity.kt
```

## Main features

- Borrower create, view, update, and delete
- Loan create, view, update, and delete
- Add payment
- Automatic total paid and remaining amount calculation
- Summary dashboard
- Manual import and export update flow
- Version tracking through `app_state`
- Edit locking when sync is not safe

## Home screen summary

The home screen shows:

- current data version
- sync status
- total principal
- total collected
- total remaining
- active loans count
- overdue count

The main home actions are:

- View Records
- Add Loan
- Add Payment
- Import Received Update
- Save & Send Update

## pubspec.yaml dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  device_info_plus: ^11.2.2
  file_picker: ^8.1.6
  intl: ^0.20.2
  path: ^1.9.0
  path_provider: ^2.1.5
  provider: ^6.1.2
  share_plus: ^10.1.4
  sqflite: ^2.4.1
  uuid: ^4.5.1
```

## SQLite schema

The local database file is `money_loan.db`.

```sql
CREATE TABLE borrowers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  note TEXT,
  created_at TEXT,
  updated_at TEXT
);

CREATE TABLE loans (
  id TEXT PRIMARY KEY,
  borrower_id TEXT NOT NULL,
  principal REAL NOT NULL,
  interest_value REAL NOT NULL,
  interest_type TEXT NOT NULL,
  total_repayable REAL NOT NULL,
  amount_paid REAL NOT NULL DEFAULT 0,
  remaining_amount REAL NOT NULL,
  start_date TEXT,
  due_date TEXT,
  status TEXT NOT NULL,
  note TEXT,
  created_at TEXT,
  updated_at TEXT,
  FOREIGN KEY (borrower_id) REFERENCES borrowers (id) ON DELETE CASCADE
);

CREATE TABLE payments (
  id TEXT PRIMARY KEY,
  loan_id TEXT NOT NULL,
  amount REAL NOT NULL,
  payment_date TEXT NOT NULL,
  note TEXT,
  created_at TEXT,
  FOREIGN KEY (loan_id) REFERENCES loans (id) ON DELETE CASCADE
);

CREATE TABLE app_state (
  key TEXT PRIMARY KEY,
  value TEXT
);

CREATE INDEX idx_loans_borrower_id ON loans (borrower_id);
CREATE INDEX idx_loans_due_date ON loans (due_date);
CREATE INDEX idx_payments_loan_id ON payments (loan_id);
```

## app_state keys

The `app_state` table stores:

- `current_version`
- `last_imported_at`
- `last_exported_at`
- `last_exported_version`
- `sync_status`
- `device_name`
- `pending_import_path`
- `pending_import_version`
- `sample_seeded`

## Sync file format

Exported file extension:

- `.mloan`

Internal format:

```json
{
  "appVersion": 1,
  "dataVersion": 12,
  "exportedAt": "2026-04-02T09:30:00.000Z",
  "exportedBy": "Samsung SM-A145F",
  "borrowers": [],
  "loans": [],
  "payments": []
}
```

## Mandatory sync behavior implemented

- The app stores `current_version` in `app_state`
- Every borrower, loan, payment, or delete action increments the version
- After every save, `sync_status` becomes `needs_export`
- After every save, a fresh `.mloan` file is written locally
- After every save, the user is strongly prompted to send the update immediately
- Imported files must contain `dataVersion`
- Imported files are rejected when `dataVersion <= current_version`
- The app creates an automatic backup before import
- On successful import, `current_version` becomes the imported `dataVersion`
- On successful import, `sync_status` becomes `ready`
- Editing is blocked when a newer import is pending
- Editing is also blocked while the app is waiting for the latest local update to be sent

## Import and export flow

1. User changes borrower, loan, payment, or deletes a record.
2. The app increments `current_version`.
3. The app writes a fresh `.mloan` JSON file.
4. `sync_status` becomes `needs_export`.
5. The app shows a strong prompt asking the user to send the update now.
6. When the user shares successfully, `sync_status` returns to `ready`.
7. When another phone sends a newer `.mloan`, the user imports it.
8. The app backs up local data, validates the file, and replaces local borrower, loan, and payment tables with the imported package.

## Android custom file-open integration notes

The Android side is already wired to accept `.mloan` files from Telegram, Viber, and file apps.

Relevant files:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/moneyloan/MainActivity.kt`

What the Android integration does:

- registers `VIEW` and `SEND` intent filters
- accepts broad MIME types because messaging apps often send generic file types
- copies incoming `content://` files into app cache
- keeps only `.mloan` files
- passes the cached local file path into Flutter using a method channel
- lets Flutter validate `dataVersion` and JSON contents before import

Method channel name:

```text
money_loan/intents
```

## Setup instructions

1. Install Flutter and Android Studio.
2. Run `flutter pub get`.
3. If standard Flutter wrapper files are missing locally, run `flutter create .` once.
4. Make sure these custom Android files still match after any regeneration:
   - `android/app/src/main/AndroidManifest.xml`
   - `android/app/src/main/kotlin/com/example/moneyloan/MainActivity.kt`
   - `android/app/src/main/res/values/styles.xml`
5. Run the app with `flutter run`.

## Build APK

```bash
flutter build apk
```

## Notes

- The current app entry is `lib/main.dart`, which starts `lib/app/app.dart`.
- The active UI uses the `lib/app`, `lib/core`, `lib/data`, `lib/features`, and `lib/widgets` structure.
- Older prototype files may still exist in the repo, but the active application flow now uses the structure above.
