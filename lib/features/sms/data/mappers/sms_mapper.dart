import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/features/sms/domain/entities/message_template.dart';
import 'package:zexano_sms/features/sms/domain/entities/sms_message.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_recipient.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

class SmsMapper {
  static SmsRecipient recipientToDomain(db.MessageHistoryData row) {
    return SmsRecipient(
      id: row.id,
      smsMessageId: row.batchId,
      contactId: row.contactId,
      phoneNumber: row.targetPhone,
      contactName: row.contactName,
      status: row.executionStatus,
      sentAt: row.sentAt,
    );
  }

  static db.MessageHistoryCompanion recipientToInsertCompanion(
    SmsRecipient recipient,
    String tenantId,
  ) {
    return db.MessageHistoryCompanion.insert(
      id: recipient.id,
      tenantId: tenantId,
      batchId: recipient.smsMessageId,
      contactName: recipient.contactName,
      contactId: Value(recipient.contactId),
      targetPhone: recipient.phoneNumber,
      messageBody: '',
      channelType: 'sms',
      executionStatus: recipient.status,
      timestamp: recipient.sentAt ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
    );
  }

  static List<SmsRecipient> recipientsFromRows(List<db.MessageHistoryData> rows) {
    return rows.map(recipientToDomain).toList();
  }

  static SmsMessage messageFromBatchRows(
    String batchId,
    String tenantId,
    List<db.MessageHistoryData> rows,
  ) {
    if (rows.isEmpty) {
      throw ArgumentError('Cannot build SmsMessage from empty rows');
    }
    final first = rows.first;
    // Both 'sent' and 'delivered' count as successes.
    final sent = rows.where((r) => MessageStatusService.isSuccess(r.executionStatus)).length;
    final failed = rows.where((r) => MessageStatusService.isFailed(r.executionStatus)).length;
    final queued = rows.where((r) => MessageStatusService.isPending(r.executionStatus)).length;
    final sentAtValues =
        rows.where((r) => r.sentAt != null).map((r) => r.sentAt!).toList();
    sentAtValues.sort();
    final latestSentAt = sentAtValues.isNotEmpty ? sentAtValues.last : null;

    final status = MessageStatusService.deriveBatchStatus(
      sentCount: sent,
      failedCount: failed,
      queuedCount: queued,
      total: rows.length,
    );

    return SmsMessage(
      id: batchId,
      tenantId: tenantId,
      messageBody: first.messageBody,
      channelType: first.channelType,
      status: status,
      totalRecipients: rows.length,
      sentCount: sent,
      failedCount: failed,
      createdAt: first.timestamp,
      sentAt: latestSentAt,
    );
  }

  static db.MessageHistoryCompanion historyRowCompanion({
    required String id,
    required String tenantId,
    required String batchId,
    required String targetPhone,
    required String messageBody,
    /// [peerId] is MANDATORY — 'sms:' + normalize(phone).
    /// Making it required ensures every write path sets it at compile time.
    /// A NULL peer_id means the Conversation trigger never fires.
    required String peerId,
    String channelType = 'sms',
    /// 'queued' by default — SmsSentReceiver updates to 'sent'/'failed' async.
    String executionStatus = 'queued',
    String contactName = '',
    String? contactId,
    /// Open text field — Allowlist in trigger: 'manual' | 'contact' | 'inbound'
    /// create Conversations. 'campaign' | 'group' do NOT.
    String sourceType = 'manual',
    /// 'outbound' for sent messages, 'inbound' for received SMS.
    String direction = 'outbound',
    String? groupId,
    int? timestamp,
    int? sentAt,
  }) {
    return db.MessageHistoryCompanion.insert(
      id: id,
      tenantId: tenantId,
      batchId: batchId,
      contactName: contactName,
      contactId: Value(contactId),
      targetPhone: targetPhone,
      messageBody: messageBody,
      channelType: channelType,
      executionStatus: executionStatus,
      timestamp: timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      sourceType: Value(sourceType),
      direction: Value(direction),
      groupId: Value(groupId),
      peerId: Value(peerId),
    );
  }

  static MessageTemplate templateToDomain(db.MessageTemplate row) {
    return MessageTemplate(
      id: row.id,
      tenantId: row.tenantId,
      title: row.title,
      bodyContent: row.bodyContent,
      createdAt: row.createdAt,
    );
  }

  static List<MessageTemplate> templatesToDomain(
      List<db.MessageTemplate> rows) {
    return rows.map(templateToDomain).toList();
  }

  static db.MessageTemplatesCompanion templateToCompanion(
    MessageTemplate template,
  ) {
    return db.MessageTemplatesCompanion.insert(
      id: template.id,
      tenantId: template.tenantId,
      title: template.title,
      bodyContent: template.bodyContent,
      createdAt: template.createdAt,
    );
  }
}
