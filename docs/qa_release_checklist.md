# QA / Release Checklist — Zexano SMS

## Pre-Release Checks

### Code Quality
- [ ] `flutter analyze` reports **0 errors, 0 warnings**
- [ ] No `// ignore` comments left in production code without justification
- [ ] No `print()` or `debugPrint()` statements in production code
- [ ] No `TODO` or `FIXME` comments in production code
- [ ] Lint rules are appropriate for release

### Testing
- [ ] Unit tests all pass: `flutter test --exclude-tags=integration`
- [ ] Integration tests all pass: `flutter test test/integration/`
- [ ] Coverage report generated and reviewed: `flutter test --exclude-tags=integration --coverage`
- [ ] No flaky tests identified (run suite 3 times consecutively)
- [ ] Widget tests pass on both phone and tablet form factors (if applicable)

### Platform: Android
- [ ] Release APK builds: `flutter build apk --release`
- [ ] Release AAB builds: `flutter build appbundle --release`
- [ ] `android/key.properties` exists and is in `.gitignore`
- [ ] Signing is configured correctly: `jarsigner -verify` succeeds
- [ ] `minifyEnabled true` and ProGuard rules are applied
- [ ] `AndroidManifest.xml` has correct permissions for release (INTERNET removed)
- [ ] `applicationId` is the production value (not `com.example.*`)
- [ ] App icon is bundled at all required mipmap densities
- [ ] App display name / label is correct

### Platform: iOS
- [ ] Archive builds successfully: `flutter build ios --release --no-codesign`
- [ ] Xcode archive exports without errors
- [ ] Bundle identifier is the production value (not `com.example.*`)
- [ ] Development team is selected in Xcode
- [ ] Distribution certificate is valid
- [ ] Provisioning profile is valid
- [ ] All required `Info.plist` keys are present
- [ ] Usage description strings are provided for any requested permissions
- [ ] App icon is bundled at all required sizes

### Functional: Core Features
- [ ] Contact CRUD: create, read, update, delete
- [ ] Contact search works
- [ ] Group CRUD: create, read, update, delete
- [ ] Group membership management (add/remove contacts)
- [ ] Message compose: character counting, segment estimation
- [ ] Template management: create, edit, delete, select
- [ ] Recipient selection: contacts, groups, manual entry
- [ ] Message history: list, filter, detail, statistics
- [ ] WhatsApp staging: compose, stage, progress tracking
- [ ] Settings: language, theme, throttle, backup prefs
- [ ] Backup: create, encrypt/decrypt, restore, integrity check
- [ ] Reset settings: non-destructive reset preserves language/theme

### Functional: Localization
- [ ] English locale: all screens render correct English strings
- [ ] Arabic locale: all screens render correct Arabic strings
- [ ] LTR layout works correctly
- [ ] RTL layout works correctly for Arabic
- [ ] Date/number formatting matches locale

### Functional: Theme
- [ ] Light theme: colors and contrast are correct
- [ ] Dark theme: colors and contrast are correct
- [ ] System default: follows device theme

### Performance & Stability
- [ ] App launches within 5 seconds on reference device
- [ ] Scroll views (contacts, groups, history) perform smoothly
- [ ] No crashes during CRUD operations
- [ ] No memory leaks during repeated navigation
- [ ] Database queries complete within 500ms for typical datasets

### Security
- [ ] Backup passphrase is not stored in plaintext
- [ ] No sensitive data is logged
- [ ] Backup encryption uses AES-256-CBC with derived key
- [ ] No hardcoded secrets in source code
- [ ] No analytics or tracking SDKs included

### Documentation
- [ ] `README.md` is accurate and up to date
- [ ] `docs/setup_guide.md` reflects current setup steps
- [ ] `docs/testing_guide.md` reflects current test suite
- [ ] `docs/release_guide.md` reflects current release process
- [ ] `docs/privacy_policy.md` is accurate
- [ ] `docs/terms_of_service.md` is accurate
- [ ] `docs/store_listing.md` is complete
- [ ] `docs/known_limitations.md` is accurate
- [ ] `CHANGELOG.md` exists and covers all versions (create if missing)

## Release Day Checklist

### Before Release
- [ ] Version bumped in `pubspec.yaml`
- [ ] Tag created in git: `git tag v<version>`
- [ ] Release notes drafted
- [ ] APK/AAB built and tested on a physical device
- [ ] iOS archive tested on a physical device (if applicable)
- [ ] Privacy policy hosted at public URL
- [ ] Terms of service hosted at public URL

### For Google Play
- [ ] App bundle (AAB) uploaded
- [ ] Store listing filled out (title, description, screenshots, icon, feature graphic)
- [ ] Content rating questionnaire completed
- [ ] Pricing and distribution set
- [ ] App signing: upload key certificate or use Play App Signing
- [ ] Release notes (What's new) written

### For App Store (iOS)
- [ ] Archive uploaded via Xcode or Transporter
- [ ] App metadata filled out (name, subtitle, description, keywords, support URL)
- [ ] Screenshots uploaded for all required device sizes
- [ ] App rating completed
- [ ] Pricing and availability set
- [ ] Export compliance: No (uses standard iOS cryptography)
- [ ] Build submitted for review

### Post-Release
- [ ] Monitor crash reports (if crash reporting is added in future)
- [ ] Verify in-app purchase or ad-free status (if applicable)
- [ ] Respond to any App Store / Play Store review feedback
- [ ] Update release notes for next version
