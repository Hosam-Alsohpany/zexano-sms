import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/whatsapp/domain/repositories/whatsapp_repository.dart';

final whatsAppRepositoryProvider = Provider<WhatsAppRepository>((ref) {
  return sl<WhatsAppRepository>();
});
