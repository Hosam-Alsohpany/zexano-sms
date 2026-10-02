import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/backup/domain/repositories/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return sl<BackupRepository>();
});
