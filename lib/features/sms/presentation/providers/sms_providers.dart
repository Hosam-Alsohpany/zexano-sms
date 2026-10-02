import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';

final smsRepositoryProvider = Provider<SmsRepository>((ref) {
  return sl<SmsRepository>();
});

final smsSearchQueryProvider = StateProvider<String>((ref) => '');
