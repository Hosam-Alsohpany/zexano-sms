# Known Limitations — Zexano SMS

## SMS Sending

### No Real SMS Dispatch
The SMS sending layer uses a **stub implementation** (`NoopSmsDispatcher`). No actual SMS messages are sent. The architecture is designed with a pluggable `SmsDispatcher` interface, but a real platform-specific implementation (e.g., using Android's `SmsManager`) has not been wired in.

- **Impact**: The SMS compose screen, recipient selection, template management, message queuing, and history recording all function. But "sending" is simulated — messages are recorded as sent but no carrier transmission occurs.
- **Resolution**: Implement a platform-specific `SmsDispatcher` (e.g., `AndroidSmsDispatcher` using `android.telephony.SmsManager`) and declare the `SEND_SMS` permission in `AndroidManifest.xml`.

### No SMS Delivery Reports
Even when SMS sending is implemented, delivery reports depend on carrier support and the Android SMS delivery intent API. The current architecture does not handle delivery report broadcast receivers.

## WhatsApp Messaging

### No Real WhatsApp Launching
The WhatsApp layer uses a **stub implementation** (`NoopWhatsAppLauncher`). The app does not actually launch WhatsApp or detect installed WhatsApp variants on the device.

- **Impact**: The WhatsApp compose screen, recipient staging, app selection UI, and batch progress tracking all function. But "launching" and "detection" are simulated.
- **Resolution**: Implement a platform-specific `WhatsAppLauncher` (e.g., `AndroidWhatsAppLauncher` using Android Intents with `https://wa.me/{phone}?text={message}` URLs), and add `<queries>` package visibility declarations to the manifest.

### No WhatsApp Message Status Feedback
WhatsApp does not provide a public API for message delivery status. The "assisted" sending pattern (opening WhatsApp for each recipient) cannot track whether the user actually tapped send. Status tracking is manual.

## Contact Import

### Device Contact Import — Implemented (2026-06-14)
The app can now import contacts from the device's address book using the `flutter_contacts` package.

- **Status**: Implemented
- **Permissions**: `READ_CONTACTS` declared in `AndroidManifest.xml`, `NSContactsUsageDescription` in `Info.plist`
- **Import source**: When tapping "Import contacts", a dialog lets you choose between:
  - **Import from device** — reads contacts from the phone's address book and saves them to the local database
  - **Add manually** — opens the contact form for manual entry
- **Duplicate detection**: Phone numbers are normalized and compared against existing contacts; duplicates are reported but not imported.
- **Group member import**: The "Add members" screen in group details also offers an "Import from device" button when no contacts are available, so you can import contacts before selecting them as group members.

## Backup & Restore

### Local Storage Only
Backups are saved to the device's local app storage (`getApplicationDocumentsDirectory`). There is no cloud backup (Google Drive, iCloud, etc.).

- **Impact**: Backup files remain on the device. If the device is lost or the app is uninstalled, backups are lost unless manually transferred.
- **Workaround**: Users can locate backup files via a file manager and copy them off-device. File paths are displayed during backup/restore flows.

### No Incremental Backups
Each backup is a full export of all data. There is no diff or incremental backup mechanism.

## Multi-Tenant

The database schema includes a `tenants` table, but multi-tenant functionality is **not implemented** in the UI layer. All operations use a single implicit tenant.

## Permissions

- No SMS, contacts, or WhatsApp-related permissions are declared in the release `AndroidManifest.xml`.
- The `INTERNET` permission exists only in debug/profile manifests (for Flutter dev tools) and is absent in release builds.
- iOS Info.plist does not declare usage description strings (`NSSmsUsageDescription`, `NSContactsUsageDescription`).

## Testing

- Integration tests share a global `SharedPreferences` mock state and must be run separately from unit/widget tests.
- Widget tests cannot reliably test loading states due to async provider resolution timing.
- iOS integration tests require a macOS environment.

## Localization

- Only **English** and **Arabic** are supported.
- RTL layout handling in Arabic uses locale-aware Flutter widgets; custom widgets may need RTL verification.
- The theme settings screen displays "System Default" (not "System") as the l10n string for the system theme option.

## Build Configuration

- Android namespace in `build.gradle` is `com.example.zexano_sms` (default) — should be updated to `com.zexano.sms` for production.
- iOS bundle identifier is `com.example.zexanoSms` (default) — should be updated to `com.zexano.sms` for production.
- No iOS development team is configured — must be set in Xcode before iOS builds.

## Platform Support

| Platform | Status |
|---|---|
| Android | Primary target. Build verified in CI (debug APK). |
| iOS | Configuration exists. Build requires Apple Developer Program. |
| Web | Not supported. |
| Windows | Not supported. |
| macOS | Not supported. |
| Linux | Not supported. |
