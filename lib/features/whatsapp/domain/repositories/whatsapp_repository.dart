import 'package:zexano_sms/core/errors/failures.dart';
import '../entities/assisted_session.dart';
import '../entities/staged_recipient.dart';
import '../entities/whatsapp_app.dart';
import '../models/launch_result.dart';
import '../models/preferred_app.dart';
import '../models/recipient_resolution_result.dart';
import '../models/whatsapp_validation_result.dart';
import '../value_objects/whatsapp_deeplink_payload.dart';

abstract class WhatsAppRepository {
  Future<AppResult<List<WhatsAppApp>>> getInstalledApps();

  Future<AppResult<PreferredApp>> getPreferredApp();

  Future<AppResult<void>> setPreferredApp({
    required String packageName,
    required String appName,
  });

  Future<AppResult<StagedRecipient>> stageSingleMessage({
    required String messageBody,
    required String phoneNumber,
    String? contactName,
    String? contactId,
  });

  Future<AppResult<AssistedSession>> stageBulkMessages({
    required String messageBody,
    required List<String> phoneNumbers,
    String? sessionId,
  });

  Future<AppResult<AssistedSession>> stageGroupMessages({
    required String groupId,
    required String messageBody,
  });

  Future<AppResult<RecipientResolutionResult>> buildRecipientList({
    List<String> contactIds = const [],
    List<String> groupIds = const [],
    List<String> manualPhones = const [],
  });

  Future<AppResult<WhatsAppValidationResult>> validateStagingPayload({
    required String messageBody,
    required List<String> phoneNumbers,
  });

  Future<AppResult<WhatsAppDeeplinkPayload>> generateDeeplinkPayload({
    required String phoneNumber,
    required String messageBody,
    String? packageName,
  });

  Future<AppResult<LaunchResult>> launchRecipient(String recipientId);

  Future<AppResult<StagedRecipient?>> advanceToNext(String sessionId);

  Future<AppResult<void>> saveLogEntry(StagedRecipient entry);

  Future<AppResult<List<AssistedSession>>> listStagingHistory({
    int? limit,
    int? offset,
  });

  Future<AppResult<LaunchResult>> retryFailedLaunch({
    required String sessionId,
    required String recipientId,
  });
}
