import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/settings_repository.dart';
import '../value_objects/theme_option.dart';

class UpdateThemeSetting {
  final SettingsRepository repository;

  UpdateThemeSetting(this.repository);

  Future<AppResult<void>> call(ThemeOption theme) {
    return repository.updateTheme(theme);
  }
}
