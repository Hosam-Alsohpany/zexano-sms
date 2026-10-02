import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/settings_repository.dart';

class UpdatePreferredWhatsAppApp {
  final SettingsRepository repository;

  UpdatePreferredWhatsAppApp(this.repository);

  Future<AppResult<void>> call(String? packageName) {
    return repository.updatePreferredWhatsApp(packageName);
  }
}
