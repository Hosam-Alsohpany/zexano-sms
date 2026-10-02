import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/build_info.dart';
import '../repositories/settings_repository.dart';

class GetAppInfo {
  final SettingsRepository repository;

  GetAppInfo(this.repository);

  Future<AppResult<BuildInfo>> call() {
    return repository.getBuildInfo();
  }
}
