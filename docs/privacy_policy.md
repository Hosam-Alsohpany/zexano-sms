# Privacy Policy

**Last updated:** June 13, 2026

## 1. Introduction

Zexano SMS ("we," "our," or "the App") is a local-first bulk messaging application. This Privacy Policy explains how the App handles your information.

## 2. Data Storage and Processing

### 2.1 Local Data Only
All data created and used by the App is stored locally on your device. The App does **not** transmit, upload, or sync any data to remote servers, cloud services, or third parties.

### 2.2 Data Stored
The App may store the following data locally on your device:

- **Contacts**: Names and phone numbers you add manually or import.
- **Groups**: Group names and membership associations you define.
- **Message history**: Records of message content, recipient phone numbers, timestamps, and delivery status for SMS and WhatsApp messages you send through the App.
- **Message templates**: Reusable message bodies you create.
- **WhatsApp session data**: Progress, status, and recipient information for bulk WhatsApp send operations.
- **App preferences**: Language selection, theme preference, throttle interval, and backup configuration.
- **Backup files**: Exported copies of your data, optionally encrypted, stored locally.

### 2.3 Data You Provide
You control all data entered into the App. You may add, edit, or delete contact information, groups, messages, and templates at any time through the App interface.

## 3. Permissions

### 3.1 SMS (Not Yet Implemented)
The App's architecture includes an SMS sending abstraction. **No SMS permissions are currently declared or requested.** When real SMS sending is implemented in a future release, the App will request `SEND_SMS` permission to send messages on your behalf. You will be prompted at that time and can grant or deny the permission.

### 3.2 Device Contacts (Not Yet Implemented)
The App's architecture includes a device contact import flow. **No `READ_CONTACTS` permission is currently declared or requested.** When contact import from the device address book is implemented in a future release, the App will request appropriate permissions.

### 3.3 Internet
The App does **not** require internet access. The `INTERNET` permission appears only in debug/profile Android manifests for Flutter development tool communication (hot reload, breakpoints). The release build does not include this permission.

### 3.4 WhatsApp Package Detection (Not Yet Implemented)
The App's architecture includes WhatsApp app detection. When real device-level WhatsApp detection is implemented, the App will query installed packages to identify WhatsApp variants. This is declared via the `<queries>` element in the manifest.

## 4. Third-Party Services

The App uses no third-party analytics, crash reporting, advertising, or tracking services. The following libraries are used solely for local functionality:

| Library | Purpose | Data Access |
|---|---|---|
| Drift / SQLite | Local database | None — data stays on device |
| SharedPreferences | Local key-value storage | None — data stays on device |
| Path Provider | Local file paths | None — resolves device paths only |

## 5. Data Security

- Backup files can be encrypted with AES-256-CBC using a user-provided passphrase.
- Backup integrity is verified via SHA-256 checksums.
- All data resides in the app's private storage directory, which is inaccessible to other apps on a non-rooted device.

## 6. Data Deletion

You can delete individual contacts, groups, messages, or clear all data by:
- Using the delete options within each screen.
- Using the "Reset All Settings" option in About screen (resets preferences to defaults, does not delete contacts/groups/history).
- Uninstalling the App removes all associated local data.

## 7. Children's Privacy

The App is not directed at children under 13. We do not knowingly collect any information from children.

## 8. Changes to This Policy

We may update this Privacy Policy. Changes will be reflected by the "Last updated" date at the top.

## 9. Contact

For questions about this Privacy Policy, please contact the developer at the email address listed on the app store listing.
