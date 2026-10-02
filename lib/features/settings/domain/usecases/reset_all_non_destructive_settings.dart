import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/settings_repository.dart';

class ResetAllNonDestructiveSettings {
  final SettingsRepository repository;

  ResetAllNonDestructiveSettings(this.repository);

  Future<AppResult<void>> call() {
    return repository.resetAllNonDestructiveSettings();
  }
}
