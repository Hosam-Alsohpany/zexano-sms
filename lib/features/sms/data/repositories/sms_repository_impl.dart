import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/core/phone/phone_validator.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';
import 'package:zexano_sms/features/sms/data/datasources/sms_local_source.dart';
import 'package:zexano_sms/features/sms/data/dispatchers/sms_dispatcher.dart';
import 'package:zexano_sms/features/sms/data/mappers/sms_mapper.dart';
import 'package:zexano_sms/features/sms/domain/entities/message_template.dart';
import 'package:zexano_sms/features/sms/domain/entities/sms_message.dart';
import 'package:zexano_sms/features/sms/domain/models/recipient_resolution_result.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_batch_result.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_recipient.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_retry_result.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_validation_result.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';
import 'package:zexano_sms/features/sms/domain/value_objects/sms_payload.dart';

import 'package:zexano_sms/features/sms/domain/services/sms_capability_service.dart';
import 'package:zexano_sms/core/di/injection_container.dart';

class SmsRepositoryImpl implements SmsRepository {
  final SmsLocalSource _localSource;
  final GroupsRepository _groupsRepository;
  final SmsDispatcher _dispatcher;
  final NormalizationEngine _normalizationEngine;
  final PhoneValidator _phoneValidator;
  final SmsCapabilityService? _capabilityService;
  final String _defaultTenantId;

  SmsRepositoryImpl({
    required SmsLocalSource localSource,
    required GroupsRepository groupsRepository,
    required SmsDispatcher dispatcher,
    required NormalizationEngine normalizationEngine,
    required PhoneValidator phoneValidator,
    SmsCapabilityService? capabilityService,
    String defaultTenantId = 'default-tenant',
  })  : _localSource = localSource,
        _groupsRepository = groupsRepository,
        _dispatcher = dispatcher,
        _normalizationEngine = normalizationEngine,
        _phoneValidator = phoneValidator,
        _capabilityService = capabilityService,
        _defaultTenantId = defaultTenantId;

  Future<AppResult<T>?> _checkCapabilityGate<T>() async {
    final capService = _capabilityService ??
        (sl.isRegistered<SmsCapabilityService>()
            ? sl<SmsCapabilityService>()
            : null);
    if (capService == null) return null;

    final status = await capService.checkCanSend();
    if (status == SmsCapabilityStatus.needsDefaultRole) {
      return const Left(
        PermissionFailure(
          message: 'يجب تعيين التطبيق كتطبيق الرسائل الافتراضي لإرسال الرسائل',
          code: 'DEFAULT_SMS_ROLE_REQUIRED',
        ),
      );
    } else if (status == SmsCapabilityStatus.permissionDenied) {
      return const Left(
        PermissionFailure(
          message: 'يلزم منح إذن إرسال الرسائل',
          code: 'SMS_PERMISSION_REQUIRED',
        ),
      );
    }
    return null;
  }

  @override
  Future<AppResult<SmsMessage>> sendSingleSms({
    required String messageBody,
    required String phoneNumber,
    String? contactName,
    String? contactId,
    String channelType = 'sms',
    /// Source that identifies the caller: 'contact', 'manual', etc.
    String sourceType = 'manual',
  }) async {
    final normalized = _normalizationEngine.normalize(phoneNumber);
    if (normalized.isEmpty) {
      return Left(
        ValidationFailure(
          message: 'رقم الهاتف غير صالح حسب الدولة: $phoneNumber',
          code: 'INVALID_PHONE',
        ),
      );
    }
    final validation = _phoneValidator.validate(normalized);
    if (!validation.isValid) {
      return Left(
        ValidationFailure(
          message: 'رقم الهاتف غير صالح حسب الدولة: $phoneNumber',
          code: 'INVALID_PHONE',
        ),
      );
    }

    try {
      final gate = await _checkCapabilityGate<SmsMessage>();
      if (gate != null) return gate;

      final batchId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final rowId = const Uuid().v4();
      // Canonical peerId: phone numbers, short codes, and sender IDs all handled consistently
      final peerId = _normalizationEngine.peerIdFor(phoneNumber);

      await _localSource.insertHistoryRow(
        SmsMapper.historyRowCompanion(
          id: rowId,
          tenantId: _defaultTenantId,
          batchId: batchId,
          targetPhone: normalized,
          messageBody: messageBody,
          channelType: channelType,
          contactName: contactName ?? '',
          contactId: contactId,
          executionStatus: 'queued',
          sourceType: contactId != null ? 'contact' : sourceType, // 'manual'|'contact' → Conversation
          direction: 'outbound',
          timestamp: now,
          peerId: peerId,
        ),
      );

      final dispatchResult = await _dispatcher.send(
        phoneNumber: normalized,
        messageBody: messageBody,
        channelType: channelType,
        messageId: rowId,
      );

      // Status from dispatcher: 'queued' (delivery tracking) or 'sent'/'failed'
      final persistedStatus = dispatchResult.success
          ? dispatchResult.status  // 'queued' when PendingIntent is armed
          : 'failed';

      if (persistedStatus != 'queued') {
        await _localSource.updateStatusByIdSafe(
          rowId,
          persistedStatus,
          sentAt: dispatchResult.success ? now : null,
        );
      }

      return Right(
        SmsMessage(
          id: batchId,
          tenantId: _defaultTenantId,
          messageBody: messageBody,
          channelType: channelType,
          status: persistedStatus,
          totalRecipients: 1,
          sentCount: dispatchResult.success ? 1 : 0,
          failedCount: dispatchResult.success ? 0 : 1,
          createdAt: now,
          sentAt: dispatchResult.success && persistedStatus == 'sent' ? now : null,
        ),
      );
    } on Exception catch (e) {
      return Left(
        MessagingFailure(
          message: 'Failed to send SMS: ${e.toString()}',
          code: 'SEND_SINGLE_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<SmsBatchResult>> sendBulkSms({
    required SmsPayload payload,
    String sourceType = 'manual',
    String? groupId,
  }) async {
    try {
      final gate = await _checkCapabilityGate<SmsBatchResult>();
      if (gate != null) return gate;

      final batchId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final uniquePhones = _deduplicatePhones(payload.recipients);

      // Build a phone → message_history.id map so that:
      //   1. The row IDs are consistent for insert + batch status updates
      //   2. Each phone gets a stable rowId reference before dispatch
      final phoneToRowId = <String, String>{};
      final companions = uniquePhones.map((recipient) {
        final rowId = const Uuid().v4();
        phoneToRowId[recipient.phoneNumber] = rowId;
        final peerId = _normalizationEngine.peerIdFor(recipient.phoneNumber);
        return SmsMapper.historyRowCompanion(
          id: rowId,
          tenantId: _defaultTenantId,
          batchId: batchId,
          targetPhone: recipient.phoneNumber,
          messageBody: payload.messageBody,
          channelType: payload.channelType,
          contactName: recipient.contactName,
          contactId: recipient.contactId,
          executionStatus: 'queued',
          sourceType: sourceType, // 'campaign'|'group' → no Conversation; 'manual' → Conversation
          direction: 'outbound',
          groupId: groupId,
          timestamp: now,
          peerId: peerId,
        );
      }).toList();

      await _localSource.batchInsertHistoryRows(companions);

      final phoneNumbers = uniquePhones.map((r) => r.phoneNumber).toList();
      final rowIds = phoneNumbers.map((p) => phoneToRowId[p]!).toList();

      // Pass individual row IDs so that every message gets its own PendingIntent
      // and SmsSentReceiver can update the exact DB row asynchronously.
      final summary = await _dispatcher.sendBatch(
        phoneNumbers: phoneNumbers,
        messageBody: payload.messageBody,
        channelType: payload.channelType,
        messageIds: rowIds,
      );

      // Only update FAILED rows here. Succeeded rows remain 'queued' and will
      // be updated to 'sent'/'failed' by SmsSentReceiver via PendingIntent →
      // native SQLite write → EventChannel → IncomingSmsService.
      final failed = summary.failedPhones;
      final succeededCount = phoneNumbers.length - failed.length;
      if (failed.isNotEmpty) {
        final failedIds = failed
            .map((f) => phoneToRowId[f.phoneNumber])
            .whereType<String>()
            .toList();
        if (failedIds.isNotEmpty) {
          await _localSource.updateBatchStatuses(failedIds, 'failed');
        }
      }

      return Right(
        SmsBatchResult(
          messageId: batchId,
          totalRequested: phoneNumbers.length,
          sentSuccessfully: succeededCount,
          failedCount: failed.length,
          failedPhoneNumbers: failed.map((f) => f.phoneNumber).toList(),
          status: failed.isEmpty ? 'queued' : (succeededCount > 0 ? 'partial' : 'failed'),
        ),
      );
    } on Exception catch (e) {
      return Left(
        MessagingFailure(
          message: 'Failed to send bulk SMS: ${e.toString()}',
          code: 'SEND_BULK_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<SmsBatchResult>> sendGroupSms({
    required String groupId,
    required String messageBody,
    String channelType = 'sms',
  }) async {
    try {
      final membersResult = await _groupsRepository.listContactsInGroup(groupId);
      final members = membersResult.fold(
        (failure) => throw Exception(failure.message),
        (contacts) => contacts,
      );

      if (members.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'Group has no members',
            code: 'GROUP_EMPTY',
          ),
        );
      }

      final recipients = members
          .map((c) {
            final phone = c.normalizedPhone.isNotEmpty
                ? c.normalizedPhone
                : c.phoneNumber;
            return (phone: phone, contact: c);
          })
          .where((r) => r.phone.isNotEmpty)
          .map((r) => SmsRecipient(
                id: const Uuid().v4(),
                smsMessageId: '',
                contactId: r.contact.id,
                phoneNumber: r.phone,
                contactName: r.contact.fullName,
              ))
          .toList();

      if (recipients.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'لا يوجد أعضاء بأرقام هاتف صالحة في هذه المجموعة',
            code: 'GROUP_NO_VALID_PHONES',
          ),
        );
      }

      final payload = SmsPayload(
        messageBody: messageBody,
        recipients: recipients,
        channelType: channelType,
      );

      // Pass sourceType='group' and the groupId so every row is tagged correctly.
      return sendBulkSms(
        payload: payload,
        sourceType: 'group',
        groupId: groupId,
      );
    } on Exception catch (e) {
      return Left(
        MessagingFailure(
          message: 'Failed to send group SMS: ${e.toString()}',
          code: 'SEND_GROUP_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<SmsMessage>> queueSms({
    required String messageBody,
    required List<String> phoneNumbers,
    String channelType = 'sms',
  }) async {
    try {
      final batchId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final uniquePhones = phoneNumbers.toSet().toList();

      final companions = uniquePhones.map((phone) {
        final normalized = _normalizationEngine.normalize(phone);
        final peerId = _normalizationEngine.peerIdFor(phone);
        return SmsMapper.historyRowCompanion(
          id: const Uuid().v4(),
          tenantId: _defaultTenantId,
          batchId: batchId,
          targetPhone: normalized.isNotEmpty ? normalized : phone,
          messageBody: messageBody,
          channelType: channelType,
          executionStatus: 'queued',
          sourceType: 'campaign', // queueSms is always a bulk/scheduled campaign
          direction: 'outbound',
          timestamp: now,
          peerId: peerId,
        );
      }).toList();

      await _localSource.batchInsertHistoryRows(companions);

      return Right(
        SmsMessage(
          id: batchId,
          tenantId: _defaultTenantId,
          messageBody: messageBody,
          channelType: channelType,
          status: 'queued',
          totalRecipients: uniquePhones.length,
          createdAt: now,
        ),
      );
    } on Exception catch (e) {
      return Left(
        MessagingFailure(
          message: 'Failed to queue SMS: ${e.toString()}',
          code: 'QUEUE_SMS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<SmsRetryResult>> retryFailedSms(String batchId) async {
    // Invariants #5, #6, #7, #8:
    //   - claimFailedRowsForRetry() atomically SELECT+UPDATE in one transaction.
    //   - Only rows still in 'failed' state are claimed and returned.
    //   - 'delivered', 'sent', 'received', 'queued', 'sending' are never claimed.
    //   - Rapid double-tap: second call finds empty list → returns immediately.
    try {
      final gate = await _checkCapabilityGate<SmsRetryResult>();
      if (gate != null) return gate;

      final claimedRows =
          await _localSource.claimFailedRowsForRetry(batchId);

      if (claimedRows.isEmpty) {
        // Either no failures, or all rows were already claimed by a prior call.
        return const Right(
          SmsRetryResult(totalRetried: 0, succeeded: 0),
        );
      }

      var succeeded = 0;
      var failed = 0;
      final stillFailed = <String>[];

      for (final row in claimedRows) {
        // Invariant #7 (PendingIntent armed):
        // Pass row.id as messageId so SmsSentReceiver updates the EXACT DB row
        // to 'sent'/'failed' asynchronously via native SQLite write + EventChannel.
        // This is the same path as the initial send — status flows:
        //   queued (claimed above) → [dispatcher] → SmsSentReceiver → sent/failed
        final result = await _dispatcher.send(
          phoneNumber: row.targetPhone,
          messageBody: row.messageBody,
          channelType: row.channelType,
          messageId: row.id, // ← CRITICAL: arms the PendingIntent
        );

        if (result.success) {
          // Row is now 'queued' (from the atomic claim) — SmsSentReceiver will
          // update to 'sent' or 'delivered' asynchronously. We do NOT set
          // 'sent' here because that would bypass the delivery tracking path.
          succeeded++;
        } else {
          // Dispatch failed immediately (e.g. not default SMS app, no SIM).
          // Update back to 'failed' so it remains retryable.
          await _localSource.updateStatusByIdSafe(row.id, 'failed');
          failed++;
          stillFailed.add(row.targetPhone);
        }
      }

      return Right(
        SmsRetryResult(
          totalRetried: claimedRows.length,
          succeeded: succeeded,
          failed: failed,
          stillFailedPhoneNumbers: stillFailed,
        ),
      );
    } on Exception catch (e) {
      return Left(
        MessagingFailure(
          message: 'Failed to retry SMS: ${e.toString()}',
          code: 'RETRY_SMS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<SmsMessage>> getSmsById(String id) async {
    try {
      final rows = await _localSource.getBatchRows(id);
      if (rows.isEmpty) {
        return const Left(
          DatabaseFailure(
            message: 'SMS message not found',
            code: 'SMS_NOT_FOUND',
          ),
        );
      }

      final message = SmsMapper.messageFromBatchRows(
        id,
        _defaultTenantId,
        rows,
      );
      return Right(message);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get SMS: ${e.toString()}',
          code: 'GET_SMS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<SmsMessage>>> listSmsHistory({
    int? limit,
    int? offset,
    String? channelType,
  }) async {
    try {
      final batchIds = await _localSource.listBatchIds(
        limit: limit,
        offset: offset,
        channelType: channelType,
      );

      if (batchIds.isEmpty) return const Right([]);

      final messages = <SmsMessage>[];
      for (final batchId in batchIds) {
        final rows = await _localSource.getBatchRows(batchId);
        if (rows.isNotEmpty) {
          messages.add(
            SmsMapper.messageFromBatchRows(
              batchId,
              _defaultTenantId,
              rows,
            ),
          );
        }
      }

      return Right(messages);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to list SMS history: ${e.toString()}',
          code: 'LIST_SMS_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<SmsValidationResult>> validateSmsPayload({
    required String messageBody,
    required List<String> phoneNumbers,
    String channelType = 'sms',
  }) async {
    try {
      final errors = <String>[];

      if (messageBody.trim().isEmpty) {
        errors.add('Message body is empty');
      }

      final validPhones = <String>[];
      for (final phone in phoneNumbers) {
        final normalized = _normalizationEngine.normalize(phone);
        if (normalized.isEmpty) {
          errors.add('رقم الهاتف غير صالح: $phone');
          continue;
        }
        final validation = _phoneValidator.validate(normalized);
        if (!validation.isValid) {
          errors.add('رقم الهاتف غير صالح حسب الدولة: $phone');
        } else {
          validPhones.add(normalized);
        }
      }

      if (validPhones.isEmpty) {
        errors.add('No valid phone numbers provided');
      }

      final characterCount = messageBody.length;
      final estimatedSegments = SmsPayload.calculateSegments(messageBody);

      return Right(
        SmsValidationResult(
          isValid: errors.isEmpty,
          errors: errors,
          estimatedSegments: estimatedSegments,
          characterCount: characterCount,
        ),
      );
    } on Exception catch (e) {
      return Left(
        ValidationFailure(
          message: 'Failed to validate SMS: ${e.toString()}',
          code: 'VALIDATE_SMS_ERR',
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
      var allRecipients = <SmsRecipient>[];
      final unresolved = <String>[];

      if (contactIds.isNotEmpty) {
        final contacts = await _localSource.getContactsByIds(contactIds);
        final foundIds = contacts.map((c) => c.id).toSet();
        for (final c in contacts) {
          final phone = c.normalizedPhone.isNotEmpty
              ? c.normalizedPhone
              : c.phoneNumber;
          if (phone.isNotEmpty) {
            allRecipients.add(
              SmsRecipient(
                id: const Uuid().v4(),
                smsMessageId: '',
                contactId: c.id,
                phoneNumber: phone,
                contactName: '${c.firstName} ${c.lastName}'.trim(),
              ),
            );
          }
        }
        for (final id in contactIds) {
          if (!foundIds.contains(id)) {
            unresolved.add(id);
          }
        }
      }

      if (groupIds.isNotEmpty) {
        for (final groupId in groupIds) {
          final result = await _groupsRepository.listContactsInGroup(groupId);
          result.fold(
            (_) => unresolved.add(groupId),
            (contacts) {
              for (final c in contacts) {
                final phone = c.normalizedPhone.isNotEmpty
                    ? c.normalizedPhone
                    : c.phoneNumber;
                if (phone.isNotEmpty) {
                  allRecipients.add(
                    SmsRecipient(
                      id: const Uuid().v4(),
                      smsMessageId: '',
                      contactId: c.id,
                      phoneNumber: phone,
                      contactName: c.fullName,
                    ),
                  );
                }
              }
            },
          );
        }
      }

      if (manualPhones.isNotEmpty) {
        for (final phone in manualPhones) {
          final normalized = _normalizationEngine.normalize(phone);
          if (normalized.isEmpty) continue;
          final validation = _phoneValidator.validate(normalized);
          if (!validation.isValid) continue;
          allRecipients.add(
            SmsRecipient(
              id: const Uuid().v4(),
              smsMessageId: '',
              phoneNumber: normalized,
              contactName: phone,
            ),
          );
        }
      }

      allRecipients = _deduplicatePhones(allRecipients);

      return Right(
        RecipientResolutionResult(
          resolved: allRecipients,
          unresolvedContactIds: unresolved,
        ),
      );
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to build recipient list: ${e.toString()}',
          code: 'BUILD_RECIPIENT_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<SmsBatchResult>> calculateBatchResult(
    String messageId,
  ) async {
    try {
      final rows = await _localSource.getBatchRows(messageId);
      if (rows.isEmpty) {
        return const Left(
          DatabaseFailure(
            message: 'Batch not found',
            code: 'BATCH_NOT_FOUND',
          ),
        );
      }

      final sent = rows
          .where((r) => MessageStatusService.isSuccess(r.executionStatus))
          .length;
      final failed = rows
          .where((r) => MessageStatusService.isFailed(r.executionStatus))
          .length;
      final queued = rows
          .where((r) => MessageStatusService.isPending(r.executionStatus))
          .length;
      final failedPhones = rows
          .where((r) => MessageStatusService.isFailed(r.executionStatus))
          .map((r) => r.targetPhone)
          .toList();

      final status = MessageStatusService.deriveBatchStatus(
        sentCount: sent,
        failedCount: failed,
        queuedCount: queued,
        total: rows.length,
      );

      return Right(
        SmsBatchResult(
          messageId: messageId,
          totalRequested: rows.length,
          sentSuccessfully: sent,
          failedCount: failed,
          failedPhoneNumbers: failedPhones,
          status: status,
        ),
      );
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to calculate batch result: ${e.toString()}',
          code: 'CALC_BATCH_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<MessageTemplate>>> listTemplates() async {
    try {
      final rows = await _localSource.getAllTemplates();
      return Right(SmsMapper.templatesToDomain(rows));
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to list templates: ${e.toString()}',
          code: 'LIST_TMPL_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<MessageTemplate>> getTemplateById(String id) async {
    try {
      final row = await _localSource.getTemplateById(id);
      if (row == null) {
        return const Left(
          DatabaseFailure(
            message: 'Template not found',
            code: 'TMPL_NOT_FOUND',
          ),
        );
      }
      return Right(SmsMapper.templateToDomain(row));
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get template: ${e.toString()}',
          code: 'GET_TMPL_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<MessageTemplate>> createTemplate({
    required String title,
    required String bodyContent,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final template = MessageTemplate(
        id: const Uuid().v4(),
        tenantId: _defaultTenantId,
        title: title,
        bodyContent: bodyContent,
        createdAt: now,
      );
      await _localSource.insertTemplate(
        SmsMapper.templateToCompanion(template),
      );
      return Right(template);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create template: ${e.toString()}',
          code: 'CREATE_TMPL_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<MessageTemplate>> updateTemplate(
    String id, {
    required String title,
    required String bodyContent,
  }) async {
    try {
      final existing = await _localSource.getTemplateById(id);
      if (existing == null) {
        return const Left(
          DatabaseFailure(
            message: 'Template not found',
            code: 'TMPL_NOT_FOUND',
          ),
        );
      }
      final updated = MessageTemplate(
        id: id,
        tenantId: existing.tenantId,
        title: title,
        bodyContent: bodyContent,
        createdAt: existing.createdAt,
      );
      await _localSource.updateTemplate(
        SmsMapper.templateToCompanion(updated),
      );
      return Right(updated);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update template: ${e.toString()}',
          code: 'UPDATE_TMPL_ERR',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> deleteTemplate(String id) async {
    try {
      await _localSource.deleteTemplate(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete template: ${e.toString()}',
          code: 'DELETE_TMPL_ERR',
        ),
      );
    }
  }

  List<SmsRecipient> _deduplicatePhones(List<SmsRecipient> recipients) {
    final seen = <String>{};
    final result = <SmsRecipient>[];
    for (final r in recipients) {
      if (seen.add(r.phoneNumber)) {
        result.add(r);
      }
    }
    return result;
  }
}
