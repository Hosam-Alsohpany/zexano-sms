import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetAppSettings {
  final SettingsRepository repository;

  GetAppSettings(this.repository);

  Future<AppResult<AppSettings>> call() {
    return repository.getSettings();
  }
}
