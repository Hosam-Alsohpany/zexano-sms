import 'package:zexano_sms/core/errors/failures.dart';
import '../models/preferred_app.dart';
import '../repositories/whatsapp_repository.dart';

class GetPreferredApp {
  final WhatsAppRepository repository;

  GetPreferredApp(this.repository);

  Future<AppResult<PreferredApp>> call() {
    return repository.getPreferredApp();
  }
}
