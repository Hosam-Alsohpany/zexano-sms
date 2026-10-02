# Testing Guide — Zexano SMS

## Test Suite Overview

The project contains **150+ tests** across 16 test files covering three layers:

### Test Layers

| Layer | Directory | Count | Purpose |
|---|---|---|---|
| Unit — Domain | `test/unit/` | ~110+ | Entities, value objects, use cases, services |
| Unit — Data | `test/unit/features/*/data/` | ~25 | Repository implementations, services |
| Widget | `test/widget/` | ~8 | Screen rendering, user interaction |
| Integration | `test/integration/` | 8 | SharedPreferences persistence round-trips |

## Running Tests

### All Non-Integration Tests

```bash
flutter test --exclude-tags=integration
```

### Specific Test Files

```bash
# Domain entity tests
flutter test test/unit/features/settings/domain/app_settings_test.dart

# Repository tests
flutter test test/unit/features/settings/data/settings_repository_impl_test.dart

# Service tests
flutter test test/unit/features/backup/data/encryption_service_test.dart
flutter test test/unit/features/backup/data/integrity_service_test.dart

# Widget tests
flutter test test/widget/settings/language_settings_screen_test.dart
flutter test test/widget/settings/theme_settings_screen_test.dart
flutter test test/widget/settings/about_screen_test.dart
flutter test test/widget/shell_screen_test.dart

# Integration tests
flutter test test/integration/settings_persistence_test.dart
```

### Coverage

```bash
flutter test --exclude-tags=integration --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
# Open coverage/html/index.html in browser
```

## Test Architecture

### Unit Tests

- **Mocking framework**: [mocktail](https://pub.dev/packages/mocktail) ^1.0.0
- **Pattern**: Create `MockSettingsRepository` with `Mock` class, stub methods with `when(() => mock.method()).thenAnswer(...)`
- **Overrides**: Widget tests override `settingsRepositoryProvider` (not `settingsProvider`) to inject mocks at the repository level
- **Dartz**: Use `Right(value)` and `Left(Failure(...))` to simulate success/failure

### Integration Tests

- Use `SharedPreferences.setMockInitialValues({})` for a pure in-memory backend
- Test full round-trips: write → read → verify
- No file I/O, no platform dependencies

### Widget Tests

- Use `tester.pumpWidget(createTestApp(mockRepo))` with a test `ProviderScope` wrapper
- Use `tester.pumpAndSettle()` to resolve async providers
- Find elements with `find.text(...)`, `find.byIcon(...)`, `find.widgetWithText(...)`

## Known Testing Constraints

1. **Loading states**: Async providers (Riverpod `FutureProvider`) resolve before the first frame renders, making loading-state widget tests unreliable. If you need to test loading, introduce an explicit delay in the mock.
2. **Snackbars**: ScaffoldMessenger showSnackBar is async. Use `tester.pump()` after triggering to see the snackbar.
3. **Dialogs**: `showDialog` is async. Use `tester.pumpAndSettle()` after the trigger.
4. **Integration tests**: Must run separately from unit/widget tests because they use `SharedPreferences.setMockInitialValues` globally.

## CI Integration

Tests are run automatically in CI (see `.github/workflows/ci.yml`):

| Job | Command | When |
|---|---|---|
| `analyze` | `flutter analyze` | Every push/PR to main/develop |
| `test` | `flutter test --exclude-tags=integration --coverage` | Every push/PR |
| `integration-test` | `flutter test integration_test/` | Every push/PR |
| `build` | `flutter build apk --debug --target-platform android-arm64` | Every push/PR |

## Adding New Tests

1. Create test file in the appropriate directory under `test/`.
2. Follow existing naming conventions: `*_test.dart`.
3. For unit tests: use `test()` or `group()` from `package:flutter_test`.
4. For widget tests: use `testWidgets()`.
5. For integration tests: add tag `integration` (`@TestOn('vm')` is implicit).
6. Run `flutter test --exclude-tags=integration` to verify no regressions.
