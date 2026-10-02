# Store Listing — Technical / Specification Document

## App Identity

| Field | Value |
|---|---|
| **App Name** | Zexano SMS |
| **Subtitle** (optional) | SMS & WhatsApp Bulk Messenger |
| **Package Name** (Android) | `com.zexano.sms` |
| **Bundle ID** (iOS) | `com.zexano.sms` |
| **Version** | 1.0.0 |
| **Build Number** | 1 |
| **Category** | Productivity / Communication |
| **Content Rating** | Everyone (no objectionable content) |
| **Price** | Free |
| **In-App Purchases** | None |

## Short Description (80 characters max)

Send bulk SMS and WhatsApp messages. Manage contacts, groups, and message history locally.

## Full Description

**Zexano SMS** is a privacy-first, local-only application for organizing contacts and sending bulk messages via SMS and WhatsApp channels.

**Features:**

- **Contact Management** — Add, edit, search, and organize contacts. Tag and favorite contacts for quick access.
- **Group Management** — Create groups and add contacts in bulk. View and manage group membership.
- **Bulk SMS** — Compose messages, select recipients from contacts/groups, and send in bulk. Use message templates for frequently sent content.
- **Assisted WhatsApp Sending** — Stage recipients and step through them one at a time with pre-filled messages via WhatsApp deep links.
- **Message History** — Unified timeline of all sent messages with filtering by channel, status, date, and contact. View statistics and delivery summaries.
- **Local Backup & Restore** — Export all data as encrypted or unencrypted JSON. Verify backup integrity with SHA-256 checksums. Full restore with preview.
- **Customization** — Light/dark/system theme. English/Arabic language support. Configurable send throttle.
- **Privacy-First** — All data stays on your device. No accounts, no cloud sync, no data collection.

**Important Notes:**
- Real SMS sending and WhatsApp launching are architectural capabilities that require per-device platform implementation. The App manages data, templates, queues, and history; actual message dispatch depends on device SMS capabilities and WhatsApp being installed.
- Users are responsible for complying with applicable anti-spam laws and obtaining recipient consent before sending bulk messages.

## Keywords (iOS)

bulk, sms, whatsapp, messaging, contacts, groups, broadcast, marketing

## Screenshots & Media

| Requirement | Specification |
|---|---|
| **Phone screenshots** | 6.7" display (1290×2796 px) or 6.5" display (1242×2688 px) |
| **Number of screenshots** | 4–6 per device |
| **Suggested screenshot content** | 1. Contacts list, 2. Group detail, 3. Message compose, 4. History timeline, 5. Backup settings, 6. Theme/language settings |
| **Feature graphic** (Android) | 1024×500 px PNG |
| **App icon** | 1024×1024 px PNG (iOS) / adaptive icon (Android) |
| **Video preview** (optional) | 15–30 seconds, portrait orientation |

## Promotional Text (170 characters max)

Organize contacts, send bulk messages, track history. All data stays on your device. No account required. English & Arabic supported.

## Privacy Policy URL

`https://<your-domain>/privacy` (see `docs/privacy_policy.md` for content)

## Terms of Service URL

`https://<your-domain>/terms` (see `docs/terms_of_service.md` for content)

## Support URL

`https://<your-domain>/support` (or email link)

## Marketing URL (optional)

`https://<your-domain>/`

## Android-Specific

| Setting | Value |
|---|---|
| **App signing** | Use Play App Signing (upload key in `android/`) |
| **Min SDK** | 21 (Android 5.0) |
| **Target SDK** | 34 (Android 14) |
| **Permissions** | None for release (INTERNET is debug-only) |

## iOS-Specific

| Setting | Value |
|---|---|
| **Minimum OS version** | 12.0 |
| **Required capabilities** | None |
| **Supported orientations** | Portrait, Landscape Left, Landscape Right |
| **iPad orientations** | All four |
| **Encryption export** | No (App uses only standard iOS cryptography via Flutter SDK) |
