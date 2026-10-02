import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/settings_repository.dart';

class ValidateSettingsValue {
  final SettingsRepository repository;

  ValidateSettingsValue(this.repository);

  Future<AppResult<bool>> call(String key, dynamic value) {
    return repository.validateSettingValue(key, value);
  }
}
