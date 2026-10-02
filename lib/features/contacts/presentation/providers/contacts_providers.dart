import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:zexano_sms/features/contacts/domain/usecases/create_contact.dart';
import 'package:zexano_sms/features/contacts/domain/usecases/get_contact_by_id.dart';
import 'package:zexano_sms/features/contacts/domain/usecases/update_contact.dart';

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return sl<ContactsRepository>();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Use-case providers ──────────────────────────────────────────────────────

final createContactUseCaseProvider = Provider<CreateContact>((ref) {
  return CreateContact(ref.read(contactsRepositoryProvider));
});

final updateContactUseCaseProvider = Provider<UpdateContact>((ref) {
  return UpdateContact(ref.read(contactsRepositoryProvider));
});

final getContactByIdUseCaseProvider = Provider<GetContactById>((ref) {
  return GetContactById(ref.read(contactsRepositoryProvider));
});

// ── Utility providers ───────────────────────────────────────────────────────

final normalizationEngineProvider = Provider<NormalizationEngine>((ref) {
  return sl<NormalizationEngine>();
});
