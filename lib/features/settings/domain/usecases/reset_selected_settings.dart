import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/settings_repository.dart';

class ResetSelectedSettings {
  final SettingsRepository repository;

  ResetSelectedSettings(this.repository);

  Future<AppResult<void>> call(List<String> settingKeys) {
    return repository.resetSettings(settingKeys);
  }
}
