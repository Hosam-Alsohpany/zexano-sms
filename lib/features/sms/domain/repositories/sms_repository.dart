import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/message_template.dart';
import '../entities/sms_message.dart';
import '../models/recipient_resolution_result.dart';
import '../models/sms_batch_result.dart';
import '../models/sms_retry_result.dart';
import '../models/sms_validation_result.dart';
import '../value_objects/sms_payload.dart';

abstract class SmsRepository {
  Future<AppResult<SmsMessage>> sendSingleSms({
    required String messageBody,
    required String phoneNumber,
    String? contactName,
    String? contactId,
    String channelType = 'sms',
    /// Open text: 'manual' | 'contact' | … Defaults to 'manual'.
    /// Automatically overridden to 'contact' when [contactId] is non-null.
    String sourceType = 'manual',
  });

  Future<AppResult<SmsBatchResult>> sendBulkSms({
    required SmsPayload payload,
    /// Open text: 'manual' | 'contact' | 'group' | …
    String sourceType = 'manual',
    /// Non-null when this bulk send originates from a group.
    String? groupId,
  });

  Future<AppResult<SmsBatchResult>> sendGroupSms({
    required String groupId,
    required String messageBody,
    String channelType = 'sms',
  });

  Future<AppResult<SmsMessage>> queueSms({
    required String messageBody,
    required List<String> phoneNumbers,
    String channelType = 'sms',
  });

  Future<AppResult<SmsRetryResult>> retryFailedSms(String messageId);

  Future<AppResult<SmsMessage>> getSmsById(String id);

  Future<AppResult<List<SmsMessage>>> listSmsHistory({
    int? limit,
    int? offset,
    String? channelType,
  });

  Future<AppResult<SmsValidationResult>> validateSmsPayload({
    required String messageBody,
    required List<String> phoneNumbers,
    String channelType = 'sms',
  });

  Future<AppResult<RecipientResolutionResult>> buildRecipientList({
    List<String> contactIds = const [],
    List<String> groupIds = const [],
    List<String> manualPhones = const [],
  });

  Future<AppResult<SmsBatchResult>> calculateBatchResult(String messageId);

  Future<AppResult<List<MessageTemplate>>> listTemplates();

  Future<AppResult<MessageTemplate>> getTemplateById(String id);

  Future<AppResult<MessageTemplate>> createTemplate({
    required String title,
    required String bodyContent,
  });

  Future<AppResult<MessageTemplate>> updateTemplate(
    String id, {
    required String title,
    required String bodyContent,
  });

  Future<AppResult<void>> deleteTemplate(String id);
}
