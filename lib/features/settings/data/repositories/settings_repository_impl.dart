import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/build_info.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/value_objects/language_code.dart';
import '../../domain/value_objects/sms_throttle_interval.dart';
import '../../domain/value_objects/theme_option.dart';
import '../datasources/settings_local_source.dart';
import '../mappers/settings_mapper.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalSource _localSource;

  SettingsRepositoryImpl(this._localSource);

  @override
  Future<AppResult<AppSettings>> getSettings() async {
    try {
      final data = _localSource.readAll();
      return Right(SettingsMapper.fromMap(data));
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<Stream<AppSettings>>> observeSettings() async {
    try {
      final stream = _localSource
          .observe()
          .map((data) => SettingsMapper.fromMap(data));
      return Right(stream);
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<void>> updateLanguage(LanguageCode language) async {
    try {
      await _localSource.writeString(
        SettingsLocalSource.keyLanguageCode,
        language.value,
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<void>> updateTheme(ThemeOption theme) async {
    try {
      await _localSource.writeString(
        SettingsLocalSource.keyThemeOption,
        theme.value,
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<void>> updatePreferredWhatsApp(String? packageName) async {
    try {
      if (packageName != null) {
        await _localSource.writeString(
          SettingsLocalSource.keyPreferredWhatsApp,
          packageName,
        );
      } else {
        await _localSource.remove(SettingsLocalSource.keyPreferredWhatsApp);
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<void>> updateSmsThrottleInterval(
    SmsThrottleInterval interval,
  ) async {
    try {
      await _localSource.writeInt(
        SettingsLocalSource.keySmsThrottleSeconds,
        interval.inSeconds,
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<void>> updateBackupPreferences({
    bool? autoBackupEnabled,
    int? autoBackupIntervalDays,
    bool? includeSms,
    bool? includeWhatsApp,
    bool? includeContacts,
  }) async {
    try {
      if (autoBackupEnabled != null) {
        await _localSource.writeBool(
          SettingsLocalSource.keyAutoBackupEnabled,
          autoBackupEnabled,
        );
      }
      if (autoBackupIntervalDays != null) {
        await _localSource.writeInt(
          SettingsLocalSource.keyAutoBackupIntervalDays,
          autoBackupIntervalDays,
        );
      }
      if (includeSms != null) {
        await _localSource.writeBool(
          SettingsLocalSource.keyBackupIncludeSms,
          includeSms,
        );
      }
      if (includeWhatsApp != null) {
        await _localSource.writeBool(
          SettingsLocalSource.keyBackupIncludeWhatsApp,
          includeWhatsApp,
        );
      }
      if (includeContacts != null) {
        await _localSource.writeBool(
          SettingsLocalSource.keyBackupIncludeContacts,
          includeContacts,
        );
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<void>> resetSettings(List<String> settingKeys) async {
    try {
      for (final key in settingKeys) {
        await _localSource.remove(key);
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<void>> resetAllNonDestructiveSettings() async {
    try {
      final destructiveKeys = {
        SettingsLocalSource.keyLanguageCode,
        SettingsLocalSource.keyThemeOption,
      };
      for (final key in SettingsLocalSource.allKeys) {
        if (!destructiveKeys.contains(key)) {
          await _localSource.remove(key);
        }
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<BuildInfo>> getBuildInfo() async {
    try {
      return const Right(BuildInfo(
        appName: 'Zexano SMS',
        packageName: 'com.zexano.sms',
        versionName: '1.0.0',
        versionCode: 1,
      ));
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }

  @override
  Future<AppResult<bool>> validateSettingValue(String key, dynamic value) async {
    try {
      final valid = switch (key) {
        SettingsLocalSource.keyLanguageCode =>
          value is String && LanguageCode.isValid(value),
        SettingsLocalSource.keyThemeOption =>
          value is String && ThemeOption.isValid(value),
        SettingsLocalSource.keySmsThrottleSeconds =>
          value is int && SmsThrottleInterval.isValidSeconds(value),
        SettingsLocalSource.keyAutoBackupEnabled => value is bool,
        SettingsLocalSource.keyAutoBackupIntervalDays =>
          value is int && value > 0,
        SettingsLocalSource.keyBackupIncludeSms => value is bool,
        SettingsLocalSource.keyBackupIncludeWhatsApp => value is bool,
        SettingsLocalSource.keyBackupIncludeContacts => value is bool,
        SettingsLocalSource.keyPreferredWhatsApp =>
          value is String || value == null,
        _ => false,
      };
      return Right(valid);
    } on Exception catch (e) {
      return Left(SettingsFailure(message: e.toString()));
    }
  }
}
