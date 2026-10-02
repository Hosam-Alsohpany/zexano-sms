import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/sms_message.dart';
import '../repositories/sms_repository.dart';

class ListSmsHistory {
  final SmsRepository repository;

  ListSmsHistory(this.repository);

  Future<AppResult<List<SmsMessage>>> call({
    int? limit,
    int? offset,
    String? channelType,
  }) {
    return repository.listSmsHistory(
      limit: limit,
      offset: offset,
      channelType: channelType,
    );
  }
}
