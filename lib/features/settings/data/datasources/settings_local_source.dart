import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalSource {
  final SharedPreferences _prefs;
  final StreamController<Map<String, dynamic>> _controller;

  SettingsLocalSource(this._prefs)
      : _controller = StreamController<Map<String, dynamic>>.broadcast();

  static const String keyLanguageCode = 'settings_language_code';
  static const String keyThemeOption = 'settings_theme_option';
  static const String keyPreferredWhatsApp = 'settings_preferred_whatsapp';
  static const String keySmsThrottleSeconds = 'settings_sms_throttle_seconds';
  static const String keyAutoBackupEnabled = 'settings_auto_backup_enabled';
  static const String keyAutoBackupIntervalDays =
      'settings_auto_backup_interval_days';
  static const String keyBackupIncludeSms = 'settings_backup_include_sms';
  static const String keyBackupIncludeWhatsApp =
      'settings_backup_include_whatsapp';
  static const String keyBackupIncludeContacts =
      'settings_backup_include_contacts';

  static const List<String> allKeys = [
    keyLanguageCode,
    keyThemeOption,
    keyPreferredWhatsApp,
    keySmsThrottleSeconds,
    keyAutoBackupEnabled,
    keyAutoBackupIntervalDays,
    keyBackupIncludeSms,
    keyBackupIncludeWhatsApp,
    keyBackupIncludeContacts,
  ];

  Map<String, dynamic> readAll() {
    final map = <String, dynamic>{};
    for (final key in allKeys) {
      final value = _prefs.get(key);
      if (value != null) {
        map[key] = value;
      }
    }
    return map;
  }

  String? readString(String key) => _prefs.getString(key);
  bool? readBool(String key) {
    final value = _prefs.get(key);
    if (value is bool) return value;
    return null;
  }

  int? readInt(String key) {
    final value = _prefs.get(key);
    if (value is int) return value;
    return null;
  }

  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
    _emit();
  }

  Future<void> writeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
    _emit();
  }

  Future<void> writeInt(String key, int value) async {
    await _prefs.setInt(key, value);
    _emit();
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
    _emit();
  }

  Future<void> clearAll() async {
    for (final key in allKeys) {
      await _prefs.remove(key);
    }
    _emit();
  }

  Stream<Map<String, dynamic>> observe() => _controller.stream;

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(readAll());
    }
  }

  void dispose() {
    _controller.close();
  }
}
