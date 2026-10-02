import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/whatsapp_app.dart';
import '../repositories/whatsapp_repository.dart';

class GetInstalledApps {
  final WhatsAppRepository repository;

  GetInstalledApps(this.repository);

  Future<AppResult<List<WhatsAppApp>>> call() {
    return repository.getInstalledApps();
  }
}
