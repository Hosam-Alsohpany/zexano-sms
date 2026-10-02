# Setup Guide — Zexano SMS

## Prerequisites

- **Flutter SDK**: 3.16.x (stable channel) — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: >=3.2.6 <4.0.0 (included with Flutter)
- **Android Studio** (for Android builds) or **Xcode** (for iOS builds)
- A physical device or emulator for testing

## Setup Steps

### 1. Clone the Repository

```bash
git clone <repository-url>
cd zexano_sms
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Code (Drift)

The project uses Drift (SQLite ORM) with code generation. Run the build runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `.g.dart` files for the database schema.

### 4. Run Static Analysis

```bash
flutter analyze
```

Expected output: 0 errors, 0 warnings. Info-level hints (prefer_const_constructors) are acceptable.

### 5. Run Tests

```bash
# Unit and widget tests
flutter test --exclude-tags=integration

# Integration tests (SharedPreferences-backed round-trips)
flutter test test/integration/

# With coverage
flutter test --exclude-tags=integration --coverage
```

### 6. Run on a Device

```bash
# Android
flutter run

# iOS
flutter run
```

## Project Structure

```
zexano_sms/
├── android/          # Android platform files
├── ios/              # iOS platform files
├── lib/
│   ├── config/       # Design system (colors, theme, typography, spacing)
│   ├── core/         # Database, DI, errors, localization, utilities
│   ├── features/     # Feature modules (contacts, groups, sms, whatsapp, history, backup, settings)
│   ├── routes/       # GoRouter configuration and shell screen
│   ├── shared/       # Shared widgets
│   └── main.dart     # App entry point
├── test/
│   ├── integration/  # Integration tests (SharedPreferences round-trips)
│   ├── unit/         # Unit tests (domain entities, services, repositories)
│   └── widget/       # Widget tests (screens, navigation)
├── docs/             # Release and documentation
└── .github/          # CI/CD workflows
```

## Environment Configuration

### local.properties

The `android/local.properties` file is created automatically when you open the project in Android Studio or run `flutter build`. It should contain:

```properties
sdk.dir=C:\\Users\\<user>\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\Users\\<user>\\flutter
```

### iOS Development Team

To build for iOS, you must set your Apple Developer team in Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the "Runner" target.
3. Under "Signing & Capabilities", select your team from the dropdown.
4. Update the bundle identifier if needed (currently `com.example.zexanoSms`).

## Troubleshooting

| Issue | Solution |
|---|---|
| `flutter analyze` shows errors | Run `dart run build_runner build` to regenerate `.g.dart` files |
| Build fails (Android) | Ensure `android/local.properties` points to a valid Android SDK path |
| Build fails (iOS) | Open `ios/Runner.xcworkspace` in Xcode and configure signing |
| Tests fail | Run `flutter clean && flutter pub get` then retry |
| Drift generator errors | Run `dart run build_runner build --delete-conflicting-outputs` |
