import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/local_database.dart';
import '../phone/phone_validator.dart';
import '../utils/normalization_engine.dart';
import '../../features/contacts/data/datasources/contacts_local_source.dart';
import '../../features/contacts/data/handlers/csv_vcf_contacts_handler.dart';
import '../../features/contacts/data/handlers/device_contacts_handler.dart';
import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../../features/groups/data/datasources/groups_local_source.dart';
import '../../features/groups/data/repositories/groups_repository_impl.dart';
import '../../features/groups/domain/repositories/groups_repository.dart';
import '../../features/history/data/datasources/history_local_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/conversations/data/datasources/conversation_local_source.dart';
import '../../features/conversations/data/repositories/conversation_repository_impl.dart';
import '../../features/conversations/domain/repositories/conversation_repository.dart';
import '../../features/sms/data/datasources/sms_local_source.dart';
import '../../features/sms/data/dispatchers/sms_dispatcher.dart';
import '../../features/sms/data/repositories/sms_repository_impl.dart';
import '../../features/sms/domain/repositories/sms_repository.dart';
import '../../features/whatsapp/data/datasources/whatsapp_local_source.dart';
import '../../features/whatsapp/data/launcher/whatsapp_launcher.dart';
import '../../features/whatsapp/data/repositories/whatsapp_repository_impl.dart';
import '../../features/whatsapp/domain/repositories/whatsapp_repository.dart';
import '../../features/backup/data/datasources/backup_local_source.dart';
import '../../features/backup/data/repositories/backup_repository_impl.dart';
import '../../features/backup/data/services/encryption_service.dart';
import '../../features/backup/data/services/integrity_service.dart';
import '../../features/backup/domain/repositories/backup_repository.dart';
import '../../features/settings/data/datasources/settings_local_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/sms/data/services/incoming_sms_service.dart';
import '../../features/sms/domain/services/sms_capability_service.dart';
import '../../shared/contact_identity_resolver.dart';

/// Returns true only on Android and iOS — the platforms that actually support
/// native SMS sending and WhatsApp deep-link launching at runtime.
bool _isMobilePlatform() {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerSingleton<AppDatabase>(AppDatabase());
  sl.registerSingleton<NormalizationEngine>(NormalizationEngine());
  sl.registerSingleton<PhoneValidator>(PhoneValidator());
  sl.registerSingleton<DeviceContactsHandler>(DeviceContactsHandler());
  sl.registerSingleton<CsvVcfContactsHandler>(CsvVcfContactsHandler());
  sl.registerSingleton<ContactsLocalSource>(
    ContactsLocalSource(sl<AppDatabase>()),
  );
  sl.registerSingleton<ContactsRepository>(
    ContactsRepositoryImpl(
      localSource: sl<ContactsLocalSource>(),
      normalizationEngine: sl<NormalizationEngine>(),
    ),
  );
  sl.registerSingleton<GroupsLocalSource>(
    GroupsLocalSource(sl<AppDatabase>()),
  );
  sl.registerSingleton<GroupsRepository>(
    GroupsRepositoryImpl(
      localSource: sl<GroupsLocalSource>(),
    ),
  );
  sl.registerSingleton<SmsLocalSource>(
    SmsLocalSource(sl<AppDatabase>(), sl<NormalizationEngine>()),
  );
  // SmsCapabilityService: single gate for Default SMS Role + permission checks.
  // Must be registered BEFORE SmsDispatcher and SmsRepository.
  // Invariant #1: all send paths check this before creating any DB rows.
  sl.registerSingleton<SmsCapabilityService>(SmsCapabilityService());
  // ContactIdentityResolver: unified name resolution (Invariants #3 & #4).
  // Registered after SmsLocalSource and NormalizationEngine.
  sl.registerSingleton<ContactIdentityResolver>(
    ContactIdentityResolver(
      localSource: sl<SmsLocalSource>(),
      normalizationEngine: sl<NormalizationEngine>(),
    ),
  );
  // Wire the real SMS dispatcher.
  // On Android: AndroidSmsDispatcher uses SmsManager via platform channel.
  // On iOS: SMS sending is not supported via programmatic API.
  // On other platforms: fails with a clear error.
  final _smsMobileCapable = _isMobilePlatform();
  sl.registerSingleton<SmsDispatcher>(
    _smsMobileCapable && Platform.isAndroid
        ? ThrottledSmsDispatcher(
            AndroidSmsDispatcher(),
            config: const SmsThrottleConfig(delayBetweenMessagesMs: 200),
          )
        : CapabilityAwareSmsDispatcher(
            canSend: _smsMobileCapable,
            capabilityError: _smsMobileCapable
                ? null
                : 'SMS sending is not supported on this platform',
          ),
  );
  sl.registerSingleton<SmsRepository>(
    SmsRepositoryImpl(
      localSource: sl<SmsLocalSource>(),
      groupsRepository: sl<GroupsRepository>(),
      dispatcher: sl<SmsDispatcher>(),
      normalizationEngine: sl<NormalizationEngine>(),
      phoneValidator: sl<PhoneValidator>(),
    ),
  );
  sl.registerSingleton<WhatsAppLocalSource>(
    WhatsAppLocalSource(sl<AppDatabase>()),
  );
  // Wire the real capability-aware launcher.
  // On Android/iOS it reports canDetect=true and canLaunch=true;
  // on other platforms it reports both as false so call-sites receive an
  // honest failure instead of a fabricated success.
  final _waMobileCapable = _isMobilePlatform();
  sl.registerSingleton<WhatsAppLauncher>(
    CapabilityAwareWhatsAppLauncher(
      canDetect: _waMobileCapable,
      canLaunch: _waMobileCapable,
      capabilityError: _waMobileCapable
          ? null
          : 'WhatsApp launching is not supported on this platform',
    ),
  );
  sl.registerSingleton<WhatsAppRepository>(
    WhatsAppRepositoryImpl(
      localSource: sl<WhatsAppLocalSource>(),
      launcher: sl<WhatsAppLauncher>(),
      groupsRepository: sl<GroupsRepository>(),
      contactsLocalSource: sl<ContactsLocalSource>(),
      normalizationEngine: sl<NormalizationEngine>(),
    ),
  );
  sl.registerSingleton<HistoryLocalSource>(
    HistoryLocalSource(sl<AppDatabase>()),
  );
  sl.registerSingleton<HistoryRepository>(
    HistoryRepositoryImpl(
      localSource: sl<HistoryLocalSource>(),
    ),
  );
  sl.registerSingleton<ConversationLocalSource>(
    ConversationLocalSource(sl<AppDatabase>()),
  );
  sl.registerSingleton<ConversationRepository>(
    ConversationRepositoryImpl(
      sl<ConversationLocalSource>(),
      sl<SmsDispatcher>(),
      sl<AppDatabase>(),
      sl<SmsLocalSource>(),
    ),
  );
  sl.registerSingleton<EncryptionService>(EncryptionService());
  sl.registerSingleton<IntegrityService>(IntegrityService());
  sl.registerSingleton<BackupLocalSource>(
    BackupLocalSource(sl<AppDatabase>()),
  );
  sl.registerSingleton<BackupRepository>(
    BackupRepositoryImpl(
      localSource: sl<BackupLocalSource>(),
      encryptionService: sl<EncryptionService>(),
      integrityService: sl<IntegrityService>(),
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerSingleton<SettingsLocalSource>(
    SettingsLocalSource(sl<SharedPreferences>()),
  );
  sl.registerSingleton<SettingsRepository>(
    SettingsRepositoryImpl(
      sl<SettingsLocalSource>(),
    ),
  );

  // IncomingSmsService: listens on EventChannel for inbound SMS and delivery
  // status updates from Android; bridges them into the Drift database.
  final incomingSmsService = IncomingSmsService(
    localSource: sl<SmsLocalSource>(),
    normalizationEngine: sl<NormalizationEngine>(),
  );
  incomingSmsService.init();
  sl.registerSingleton<IncomingSmsService>(incomingSmsService);

  // One-time backfill: rebuild conversations from existing message_history rows.
  // Triggered by a SharedPreferences flag ('conv_backfill_v1_done') so it
  // runs only once. The 'v1' suffix allows future backfills to re-run on logic
  // changes without resetting old flags.
  const _backfillKey = 'conv_backfill_v1_done';
  if (!prefs.containsKey(_backfillKey)) {
    await sl<AppDatabase>().backfillConversationsFromHistory();
    await prefs.setBool(_backfillKey, true);
  }

  // Invariant #4: Backfill inbound contact names for rows written by Kotlin
  // with empty contactName (native receiver runs without contact resolution).
  // Runs asynchronously — does NOT block app startup or DI initialization.
  sl<ContactIdentityResolver>().backfillInboundNames();
}
