import 'dart:async';

import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class ObserveAppSettings {
  final SettingsRepository repository;

  ObserveAppSettings(this.repository);

  Future<AppResult<Stream<AppSettings>>> call() {
    return repository.observeSettings();
  }
}
