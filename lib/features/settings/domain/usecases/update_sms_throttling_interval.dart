import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/settings_repository.dart';
import '../value_objects/sms_throttle_interval.dart';

class UpdateSmsThrottlingInterval {
  final SettingsRepository repository;

  UpdateSmsThrottlingInterval(this.repository);

  Future<AppResult<void>> call(SmsThrottleInterval interval) {
    return repository.updateSmsThrottleInterval(interval);
  }
}
