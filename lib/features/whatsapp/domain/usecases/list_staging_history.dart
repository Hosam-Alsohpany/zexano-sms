import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/assisted_session.dart';
import '../repositories/whatsapp_repository.dart';

class ListStagingHistory {
  final WhatsAppRepository repository;

  ListStagingHistory(this.repository);

  Future<AppResult<List<AssistedSession>>> call({
    int? limit,
    int? offset,
  }) {
    return repository.listStagingHistory(
      limit: limit,
      offset: offset,
    );
  }
}
