import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/contacts/data/datasources/contacts_local_source.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';
import 'package:zexano_sms/features/whatsapp/data/datasources/whatsapp_local_source.dart';
import 'package:zexano_sms/features/whatsapp/data/launcher/whatsapp_launcher.dart';
import 'package:zexano_sms/features/whatsapp/data/mappers/whatsapp_mapper.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/assisted_session.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/staged_recipient.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/whatsapp_app.dart';
import 'package:zexano_sms/features/whatsapp/domain/models/launch_result.dart';
import 'package:zexano_sms/features/whatsapp/domain/models/preferred_app.dart';
import 'package:zexano_sms/features/whatsapp/domain/models/recipient_resolution_result.dart';
import 'package:zexano_sms/features/whatsapp/domain/models/whatsapp_validation_result.dart';
import 'package:zexano_sms/features/whatsapp/domain/repositories/whatsapp_repository.dart';
import 'package:zexano_sms/features/whatsapp/domain/value_objects/whatsapp_deeplink_payload.dart';

class WhatsAppRepositoryImpl implements WhatsAppRepository {
  final WhatsAppLocalSource _localSource;
  final WhatsAppLauncher _launcher;
  final GroupsRepository _groupsRepository;
  final ContactsLocalSource _contactsLocalSource;
  final NormalizationEngine _normalizationEngine;
  final String _defaultTenantId;

  static const String _preferenceId = 'preferred_whatsapp_app';

  WhatsAppRepositoryImpl({
    required WhatsAppLocalSource localSource,
    required WhatsAppLauncher launcher,
    required GroupsRepository groupsRepository,
    required ContactsLocalSource contactsLocalSource,
    required NormalizationEngine normalizationEngine,
    String defaultTenantId = 'default-tenant',
  })  : _localSource = localSource,
        _launcher = launcher,
        _groupsRepository = groupsRepository,
        _contactsLocalSource = contactsLocalSource,
        _normalizationEngine = normalizationEngine,
        _defaultTenantId = defaultTenantId;

  @override
  Future<AppResult<List<WhatsAppApp>>> getInstalledApps() async {
    try {
      final apps = await _launcher.detectInstalledApps();
      final pref = await _localSource.getPreference(_preferenceId);
      final preferredPackage = pref?.packageName;

      final result = apps.map((app) {
        if (app.packageName == preferredPackage) {
          return app.copyWith(isPreferred: true);
        }
        return app;
      }).toList();

      return Right(result);
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to detect apps: ${e.toString()}',
          code: 'DETECT_APPS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<PreferredApp>> getPreferredApp() async {
    try {
      final row = await _localSource.getPreference(_preferenceId);
      if (row == null) {
        return const Right(PreferredApp(
          packageName: '',
          appName: '',
          isSet: false,
        ));
      }
      return Right(WhatsAppMapper.preferenceToDomain(row));
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to get preference: ${e.toString()}',
          code: 'GET_PREF_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> setPreferredApp({
    required String packageName,
    required String appName,
  }) async {
    try {
      final app = PreferredApp(
        packageName: packageName,
        appName: appName,
        isSet: true,
      );
      await _localSource.upsertPreference(
        WhatsAppMapper.preferenceToCompanion(app, _preferenceId, _defaultTenantId),
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to set preference: ${e.toString()}',
          code: 'SET_PREF_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<StagedRecipient>> stageSingleMessage({
    required String messageBody,
    required String phoneNumber,
    String? contactName,
    String? contactId,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final sessionId = const Uuid().v4();
      final stagedId = const Uuid().v4();

      final session = AssistedSession(
        sessionId: sessionId,
        messageBody: messageBody,
        totalRecipients: 1,
        status: 'in_progress',
        createdAt: now,
      );

      await _localSource.insertSession(
        WhatsAppMapper.sessionToCompanion(session, _defaultTenantId),
      );

      final normalized = _normalizationEngine.normalize(phoneNumber);
      final recipient = StagedRecipient(
        id: stagedId,
        sessionId: sessionId,
        phoneNumber: normalized,
        contactName: contactName ?? '',
        contactId: contactId,
        status: 'pending',
      );

      await _localSource.insertStagedRecipient(
        WhatsAppMapper.stagedToInsertCompanion(recipient),
      );

      return Right(recipient);
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to stage single message: ${e.toString()}',
          code: 'STAGE_SINGLE_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<AssistedSession>> stageBulkMessages({
    required String messageBody,
    required List<String> phoneNumbers,
    String? sessionId,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final actualSessionId = sessionId ?? const Uuid().v4();

      final normalizedPhones = phoneNumbers
          .map((p) => _normalizationEngine.normalize(p))
          .where((p) => p.isNotEmpty)
          .toList();

      final deduplicated = normalizedPhones.toSet().toList();

      final session = AssistedSession(
        sessionId: actualSessionId,
        messageBody: messageBody,
        totalRecipients: deduplicated.length,
        status: 'in_progress',
        createdAt: now,
      );

      await _localSource.insertSession(
        WhatsAppMapper.sessionToCompanion(session, _defaultTenantId),
      );

      final companions = deduplicated.map((phone) {
        return WhatsAppMapper.stagedToInsertCompanion(
          StagedRecipient(
            id: const Uuid().v4(),
            sessionId: actualSessionId,
            phoneNumber: phone,
            status: 'pending',
          ),
        );
      }).toList();

      await _localSource.batchInsertStagedRecipients(companions);

      return Right(session.copyWith(totalRecipients: companions.length));
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to stage bulk messages: ${e.toString()}',
          code: 'STAGE_BULK_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<AssistedSession>> stageGroupMessages({
    required String groupId,
    required String messageBody,
  }) async {
    try {
      final membersResult =
          await _groupsRepository.listContactsInGroup(groupId);
      return membersResult.fold(
        (failure) => Left(
          WhatsAppFailure(
            message: 'Failed to get group members: ${failure.message}',
            code: 'STAGE_GROUP_ERR',
          ),
        ),
        (members) async {
          final phones = members
              .map((m) => _normalizationEngine.normalize(m.normalizedPhone))
              .where((p) => p.isNotEmpty)
              .toList();
          return stageBulkMessages(
            messageBody: messageBody,
            phoneNumbers: phones,
          );
        },
      );
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to stage group messages: ${e.toString()}',
          code: 'STAGE_GROUP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<RecipientResolutionResult>> buildRecipientList({
    List<String> contactIds = const [],
    List<String> groupIds = const [],
    List<String> manualPhones = const [],
  }) async {
    try {
      final staged = <StagedRecipient>[];
      final unresolvedContactIds = <String>[];

      for (final contactId in contactIds) {
        final contact = await _contactsLocalSource.getContactById(contactId);
        if (contact != null) {
          final normalized = _normalizationEngine.normalize(contact.phoneNumber);
          staged.add(StagedRecipient(
            id: const Uuid().v4(),
            sessionId: '',
            phoneNumber: normalized,
            contactName: '${contact.firstName} ${contact.lastName}'.trim(),
            contactId: contactId,
            status: 'pending',
          ));
        } else {
          unresolvedContactIds.add(contactId);
        }
      }

      for (final groupId in groupIds) {
        final membersResult =
            await _groupsRepository.listContactsInGroup(groupId);
        membersResult.fold(
          (_) {},
          (members) {
            for (final member in members) {
              final normalized =
                  _normalizationEngine.normalize(member.normalizedPhone);
              if (normalized.isNotEmpty) {
                staged.add(StagedRecipient(
                  id: const Uuid().v4(),
                  sessionId: '',
                  phoneNumber: normalized,
                  contactName:
                      '${member.firstName} ${member.lastName}'.trim(),
                  contactId: member.id,
                  status: 'pending',
                ));
              }
            }
          },
        );
      }

      for (final phone in manualPhones) {
        final normalized = _normalizationEngine.normalize(phone);
        if (normalized.isNotEmpty) {
          staged.add(StagedRecipient(
            id: const Uuid().v4(),
            sessionId: '',
            phoneNumber: normalized,
            status: 'pending',
          ));
        }
      }

      final deduplicated = _deduplicatePhones(staged);

      return Right(RecipientResolutionResult(
        resolved: deduplicated,
        unresolvedContactIds: unresolvedContactIds,
      ));
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to build recipient list: ${e.toString()}',
          code: 'BUILD_RCP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<WhatsAppValidationResult>> validateStagingPayload({
    required String messageBody,
    required List<String> phoneNumbers,
  }) async {
    try {
      final errors = <String>[];

      if (messageBody.trim().isEmpty) {
        errors.add('message_body_empty');
      }

      final validPhones = phoneNumbers
          .where((p) => _normalizationEngine.normalize(p).isNotEmpty)
          .toList();

      if (validPhones.isEmpty) {
        errors.add('no_valid_recipients');
      }

      final apps = await _launcher.detectInstalledApps();
      final hasInstalledApp = apps.any((a) => a.isInstalled);

      if (!hasInstalledApp) {
        errors.add('no_whatsapp_installed');
      }

      return Right(WhatsAppValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        estimatedCharacterCount: messageBody.length,
        hasInstalledApp: hasInstalledApp,
      ));
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to validate: ${e.toString()}',
          code: 'VALIDATE_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<WhatsAppDeeplinkPayload>> generateDeeplinkPayload({
    required String phoneNumber,
    required String messageBody,
    String? packageName,
  }) async {
    try {
      final normalized = _normalizationEngine.normalize(phoneNumber);
      if (normalized.isEmpty) {
        return const Left(
          WhatsAppFailure(
            message: 'Invalid phone number',
            code: 'INVALID_PHONE',
          ),
        );
      }

      final actualPackage = packageName ?? 'com.whatsapp';
      final intentUri =
          WhatsAppDeeplinkPayload.buildIntentUri(normalized, messageBody, actualPackage);

      return Right(WhatsAppDeeplinkPayload(
        phoneNumber: normalized,
        messageBody: messageBody,
        packageName: actualPackage,
        uri: intentUri,
      ));
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to generate deeplink: ${e.toString()}',
          code: 'DEEPLINK_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<LaunchResult>> launchRecipient(String recipientId) async {
    try {
      final row = await _localSource.getStagedRecipientById(recipientId);
      if (row == null) {
        return const Left(
          WhatsAppFailure(
            message: 'Recipient not found',
            code: 'RCP_NOT_FOUND',
          ),
        );
      }

      final recipient = WhatsAppMapper.stagedToDomain(row);
      final pref = await _localSource.getPreference(_preferenceId);
      final packageName = pref?.packageName ?? 'com.whatsapp';

      final launchResult = await _launcher.launch(
        recipientId: recipientId,
        phoneNumber: recipient.phoneNumber,
        messageBody: '',
        packageName: packageName,
      );

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final updated = recipient.copyWith(
        status: launchResult.success ? 'launched' : 'failed',
        launchSuccess: launchResult.success,
        failureReason: launchResult.failureReason,
        attemptedAt: now,
      );

      await _localSource.updateStagedRecipient(
        WhatsAppMapper.stagedToUpdateCompanion(updated),
      );

      final session =
          await _localSource.getSessionById(recipient.sessionId);
      if (session != null) {
        final completedCount =
            await _localSource.countByStatus(recipient.sessionId, 'launched');
        final failedCount =
            await _localSource.countByStatus(recipient.sessionId, 'failed');
        final currentSession = WhatsAppMapper.sessionToDomain(session);
        await _localSource.updateSession(
          WhatsAppMapper.sessionToUpdateCompanion(
            currentSession.copyWith(
              completedRecipients: completedCount,
              failedRecipients: failedCount,
            ),
          ),
        );
      }

      return Right(launchResult);
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to launch: ${e.toString()}',
          code: 'LAUNCH_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<StagedRecipient?>> advanceToNext(String sessionId) async {
    try {
      final pending = await _localSource.getPendingRecipients(sessionId);
      if (pending.isEmpty) {
        final session = await _localSource.getSessionById(sessionId);
        if (session != null) {
          final currentSession = WhatsAppMapper.sessionToDomain(session);
          await _localSource.updateSession(
            WhatsAppMapper.sessionToUpdateCompanion(
              currentSession.copyWith(
                status: 'completed',
                completedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              ),
            ),
          );
        }
        return const Right(null);
      }

      final next = WhatsAppMapper.stagedToDomain(pending.first);

      final session = await _localSource.getSessionById(sessionId);
      if (session != null) {
        final currentSession = WhatsAppMapper.sessionToDomain(session);
        await _localSource.updateSession(
          WhatsAppMapper.sessionToUpdateCompanion(
            currentSession.copyWith(
              currentIndex: currentSession.currentIndex + 1,
            ),
          ),
        );
      }

      return Right(next);
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to advance: ${e.toString()}',
          code: 'ADVANCE_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> saveLogEntry(StagedRecipient entry) async {
    try {
      await _localSource.insertStagedRecipient(
        WhatsAppMapper.stagedToInsertCompanion(entry),
      );
      return const Right(null);
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to save log: ${e.toString()}',
          code: 'SAVE_LOG_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<AssistedSession>>> listStagingHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final rows = await _localSource.getSessions(
        limit: limit,
        offset: offset,
      );
      return Right(WhatsAppMapper.sessionsToDomain(rows));
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to list history: ${e.toString()}',
          code: 'LIST_HIST_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<LaunchResult>> retryFailedLaunch({
    required String sessionId,
    required String recipientId,
  }) async {
    try {
      final row = await _localSource.getStagedRecipientById(recipientId);
      if (row == null) {
        return const Left(
          WhatsAppFailure(
            message: 'Recipient not found',
            code: 'RCP_NOT_FOUND',
          ),
        );
      }

      final recipient = WhatsAppMapper.stagedToDomain(row);
      if (!recipient.isFailed) {
        return Left(
          WhatsAppFailure(
            message: 'Recipient is not in failed state',
            code: 'NOT_FAILED',
          ),
        );
      }

      return launchRecipient(recipientId);
    } on Exception catch (e) {
      return Left(
        WhatsAppFailure(
          message: 'Failed to retry launch: ${e.toString()}',
          code: 'RETRY_LAUNCH_ERR',
        ),
      );
    }
  }

  List<StagedRecipient> _deduplicatePhones(List<StagedRecipient> recipients) {
    final seen = <String>{};
    final result = <StagedRecipient>[];
    for (final r in recipients) {
      if (seen.add(r.phoneNumber)) {
        result.add(r);
      }
    }
    return result;
  }
}
