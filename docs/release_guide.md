# Release Guide — Zexano SMS

## Versioning

Version follows the format `{major}.{minor}.{patch}+{build_number}` as defined in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

| Component | File | Description |
|---|---|---|
| Version name | `pubspec.yaml` → `version` | User-facing version (e.g., 1.0.0) |
| Build number | `pubspec.yaml` → `version` after `+` | Incremental build counter |
| Android versionName | Derived from `pubspec.yaml` | Maps to `versionName` |
| Android versionCode | `local.properties` → `flutter.versionCode` | Maps to `versionCode` |
| iOS CFBundleShortVersionString | Derived from `pubspec.yaml` | Via `FLUTTER_BUILD_NAME` |
| iOS CFBundleVersion | Derived from `pubspec.yaml` | Via `FLUTTER_BUILD_NUMBER` |

## Prerequisites

### General
- Flutter SDK 3.16.x (stable)
- All tests passing (`flutter test --exclude-tags=integration`)
- Static analysis clean (`flutter analyze` → 0 errors, 0 warnings)

### Android
- Java 11+ JDK installed
- Android SDK 34+ installed
- **Keystore file** for signing (see Keystore Setup below)
- Android NDK (included with Flutter)

### iOS
- macOS with Xcode 15+
- **Apple Developer Program** membership ($99/year)
- Distribution certificate and provisioning profile
- App Store Connect record created

## Android Release

### 1. Keystore Setup

Create a keystore if you don't have one:

```bash
keytool -genkey -v \
  -keystore /path/to/zexano-sms-upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload-key \
  -storetype PKCS12
```

Create `android/key.properties`:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload-key
storeFile=../zexano-sms-upload-key.jks
```

**Important**: Add `android/key.properties` and the `.jks` keystore file to `.gitignore`. Never commit signing credentials.

### 2. Configure Signing in build.gradle

The `android/app/build.gradle` file has a signing configuration placeholder. After creating `key.properties`, the `release` build type will use it automatically if the property file exists.

### 3. Update Version

```bash
# Edit pubspec.yaml: version: 1.0.1+2
# Commit and tag
git tag v1.0.1+2
```

### 4. Build Release APK / App Bundle

```bash
# APK (universal)
flutter build apk --release

# APK (split by ABI)
flutter build apk --release --split-per-abi

# App Bundle (preferred for Google Play)
flutter build appbundle --release
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### 5. Verify the Build

```bash
# Check APK signature
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk

# Check AAB signature
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

### 6. Upload to Google Play Console
1. Go to [Google Play Console](https://play.google.com/console/).
2. Create a new app or select existing.
3. Upload the AAB or APK under "Production" or "Internal testing" track.
4. Fill in store listing (see `docs/store_listing.md`).
5. Submit for review.

## iOS Release

### 1. App Store Connect Setup
1. Go to [App Store Connect](https://appstoreconnect.apple.com/).
2. Create a new app with bundle ID `com.zexano.sms` (or your chosen ID).
3. Set up app information, pricing, etc.

### 2. Configure Xcode Project
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Update bundle identifier to match App Store Connect record.
3. Under "Signing & Capabilities", select your Apple Developer team.
4. Ensure "Automatically manage signing" is checked.

### 3. Build and Archive

```bash
# Clean and get packages
flutter clean && flutter pub get

# Build iOS archive
flutter build ios --release --no-codesign

# Open Xcode and archive
open ios/Runner.xcworkspace
# Select Product → Archive from Xcode menu
```

### 4. Upload to App Store Connect
1. In Xcode Organizer window, select the archive.
2. Click "Distribute App" → "App Store Connect" → "Upload".
3. Follow the prompts.

### 5. Submit for Review
1. Go to App Store Connect.
2. Complete app metadata (see `docs/store_listing.md`).
3. Submit for review.

## CI Build

The CI pipeline at `.github/workflows/ci.yml` builds a debug APK on every push. For release builds, use the local build commands above.

## Post-Release Checklist

- [ ] Version tagged in git (`git tag v<version>`)
- [ ] APK/AAB uploaded to Google Play
- [ ] IPA uploaded to App Store Connect
- [ ] Release notes written
- [ ] Privacy policy URL set in store listings
- [ ] Terms of service URL set in store listings
- [ ] Internal testing track updated
- [ ] Beta testers notified
