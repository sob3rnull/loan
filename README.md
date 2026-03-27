# Money Loan

Offline Flutter Android app for a small two-phone loan tracking workflow.

## What is included

- Flutter app code in `lib/`
- SQLite storage with `sqflite`
- Manual file export/import using `.mloan`
- JSON sync package structure
- Automatic backup before import
- Large-text elderly-friendly UI
- Android intent handling for opening `.mloan` files from Telegram, Viber, or file apps

## Main folders

- `lib/core`: theme, routing, shared widgets, helpers
- `lib/data`: models, SQLite helper, repositories, sample seed logic
- `lib/services`: export/import, sharing, Android intent bridge
- `lib/screens`: home, borrower, loan, payment, import, send-update screens
- `android/app/src/main`: manifest and `MainActivity.kt` custom file-open handling

## Dependencies

The app uses these main packages from [pubspec.yaml](pubspec.yaml):

- `sqflite`
- `path_provider`
- `path`
- `share_plus`
- `file_picker`
- `provider`
- `intl`
- `uuid`
- `device_info_plus`

## Sync file format

Exported file name:

- `moneyloan_update.mloan`

Internal JSON structure:

```json
{
  "appVersion": 1,
  "dataVersion": 12,
  "exportedAt": "2026-03-20T23:10:00",
  "exportedBy": "Mom Phone",
  "borrowers": [],
  "loans": [],
  "payments": []
}
```

## Sync behavior

- Every save increases `current_version`
- Every save writes a fresh `.mloan` export file
- Every save marks sync status as `needs_export`
- The app immediately prompts the user to send the new file
- Editing is blocked when:
  - a newer update is waiting to be imported
  - unsent local changes still need to be sent
- Older update files are rejected
- Current local data is backed up before import

## Sample seed data

Sample seed data is implemented in `lib/data/seed/sample_seed_service.dart`.

For real deployment it is disabled by default in:

- `lib/core/app_config.dart`

To test with sample data, temporarily set:

```dart
static const bool seedSampleDataOnFirstLaunch = true;
```

Then run the app on a fresh install.

## Android custom file opening

The custom Android file-open support is split into:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/moneyloan/MainActivity.kt`

What it does:

- accepts `VIEW` and `SEND` intents
- copies incoming shared files from `content://` URIs into app cache
- forwards the cached local path to Flutter through a method channel
- lets Flutter validate the `.mloan` file before import

## Setup instructions

1. Install Flutter and Android Studio.
2. In this project, run `flutter pub get`.
3. If this repo does not yet have the standard Flutter-generated wrapper files on your machine, run `flutter create .` once to generate any missing boilerplate.
4. Re-check that these custom Android files still match this repo after generation:
   - `android/app/src/main/AndroidManifest.xml`
   - `android/app/src/main/kotlin/com/example/moneyloan/MainActivity.kt`
   - `android/app/src/main/res/values/styles.xml`
5. Run `flutter run`.

## Build APK

```bash
flutter build apk
```

## Notes

- This workspace was created without a local Flutter SDK available in the current shell, so `flutter pub get`, formatting, and compilation were not run here.
- The Android share filters are intentionally broad because Telegram/Viber often provide generic file MIME types; the app still validates the file contents before import.
