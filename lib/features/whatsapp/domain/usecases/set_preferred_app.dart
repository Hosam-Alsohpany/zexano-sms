import 'package:zexano_sms/core/errors/failures.dart';
import '../repositories/whatsapp_repository.dart';

class SetPreferredApp {
  final WhatsAppRepository repository;

  SetPreferredApp(this.repository);

  Future<AppResult<void>> call({
    required String packageName,
    required String appName,
  }) {
    return repository.setPreferredApp(
      packageName: packageName,
      appName: appName,
    );
  }
}
