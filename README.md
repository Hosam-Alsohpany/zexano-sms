# Zexano SMS

A privacy-first, local-only Flutter application for organizing contacts and sending bulk SMS and WhatsApp messages.

## Features

- **Contact Management** — Add, edit, search, tag, and favorite contacts.
- **Group Management** — Create groups and manage membership in bulk.
- **Bulk SMS** — Compose messages, select recipients, use templates, and send in bulk.
- **Assisted WhatsApp** — Stage recipients and step through one at a time via WhatsApp deep links.
- **Message History** — Unified timeline with filtering, statistics, and search.
- **Local Backup & Restore** — Encrypted or plain JSON export with integrity verification.
- **Customization** — Light/dark/system theme, English/Arabic localization.

## Important Notes

- **SMS and WhatsApp sending use stub implementations** (`NoopSmsDispatcher`, `NoopWhatsAppLauncher`). The architecture is ready for platform-specific dispatchers but none are wired in yet. Messages are recorded as sent but no actual carrier transmission or WhatsApp launch occurs.
- **All data stays on your device.** No accounts, no cloud sync, no data collection.

## Quick Start

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze        # Expected: 0 errors, 0 warnings
flutter test --exclude-tags=integration   # Expected: All tests pass
```

## Documentation

| Document | Description |
|---|---|
| `docs/setup_guide.md` | Development environment setup |
| `docs/testing_guide.md` | Test suite overview and instructions |
| `docs/release_guide.md` | Android and iOS release process |
| `docs/privacy_policy.md` | Privacy policy template |
| `docs/terms_of_service.md` | Terms of service template |
| `docs/store_listing.md` | App store listing specification |
| `docs/known_limitations.md` | Current known limitations |
| `docs/qa_release_checklist.md` | Pre-release QA checklist |
| `docs/integration_verification.md` | Final integration test results |

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.16.x |
| State Management | Riverpod (flutter_riverpod) |
| Routing | go_router |
| Database | Drift (SQLite ORM) |
| Local Storage | SharedPreferences |
| DI | get_it |
| Error Handling | dartz (Either) |
| Encryption | AES-256-CBC (crypto package) |
| Integrity | SHA-256 (crypto package) |
| Testing | flutter_test, mocktail, integration_test |

## CI

See `.github/workflows/ci.yml` — runs analyze, test (with coverage), integration-test, and build on every push to main/develop.

## License

Private. All rights reserved.
