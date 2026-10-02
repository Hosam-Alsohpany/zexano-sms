import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/sms_message.dart';
import '../repositories/sms_repository.dart';

class GetSmsById {
  final SmsRepository repository;

  GetSmsById(this.repository);

  Future<AppResult<SmsMessage>> call(String id) {
    return repository.getSmsById(id);
  }
}
