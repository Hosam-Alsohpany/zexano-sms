import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/settings_repository.dart';
import '../value_objects/language_code.dart';

class UpdateLanguageSetting {
  final SettingsRepository repository;

  UpdateLanguageSetting(this.repository);

  Future<AppResult<void>> call(LanguageCode language) {
    return repository.updateLanguage(language);
  }
}
