import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/settings_repository.dart';

class UpdateBackupPreferenceFlags {
  final SettingsRepository repository;

  UpdateBackupPreferenceFlags(this.repository);

  Future<AppResult<void>> call({
    bool? autoBackupEnabled,
    int? autoBackupIntervalDays,
    bool? includeSms,
    bool? includeWhatsApp,
    bool? includeContacts,
  }) {
    return repository.updateBackupPreferences(
      autoBackupEnabled: autoBackupEnabled,
      autoBackupIntervalDays: autoBackupIntervalDays,
      includeSms: includeSms,
      includeWhatsApp: includeWhatsApp,
      includeContacts: includeContacts,
    );
  }
}
