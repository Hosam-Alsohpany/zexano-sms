import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/features/whatsapp/domain/entities/assisted_session.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/staged_recipient.dart';
import 'package:zexano_sms/features/whatsapp/domain/models/preferred_app.dart';

class WhatsAppMapper {
  static AssistedSession sessionToDomain(db.AssistedSession row) {
    return AssistedSession(
      sessionId: row.sessionId,
      messageBody: row.messageBody,
      totalRecipients: row.totalRecipients,
      completedRecipients: row.completedRecipients,
      failedRecipients: row.failedRecipients,
      currentIndex: row.currentIndex,
      status: row.status,
      createdAt: row.createdAt,
      completedAt: row.completedAt,
    );
  }

  static List<AssistedSession> sessionsToDomain(
      List<db.AssistedSession> rows) {
    return rows.map(sessionToDomain).toList();
  }

  static db.AssistedSessionsCompanion sessionToCompanion(
    AssistedSession session,
    String tenantId,
  ) {
    return db.AssistedSessionsCompanion.insert(
      sessionId: session.sessionId,
      tenantId: tenantId,
      messageBody: session.messageBody,
      totalRecipients: session.totalRecipients,
      completedRecipients: session.completedRecipients,
      failedRecipients: session.failedRecipients,
      currentIndex: session.currentIndex,
      status: session.status,
      createdAt: session.createdAt,
      completedAt: Value(session.completedAt),
    );
  }

  static db.AssistedSessionsCompanion sessionToUpdateCompanion(
    AssistedSession session,
  ) {
    return db.AssistedSessionsCompanion(
      sessionId: Value(session.sessionId),
      messageBody: Value(session.messageBody),
      totalRecipients: Value(session.totalRecipients),
      completedRecipients: Value(session.completedRecipients),
      failedRecipients: Value(session.failedRecipients),
      currentIndex: Value(session.currentIndex),
      status: Value(session.status),
      completedAt: Value(session.completedAt),
    );
  }

  static StagedRecipient stagedToDomain(db.StagedRecipient row) {
    return StagedRecipient(
      id: row.id,
      sessionId: row.sessionId,
      phoneNumber: row.phoneNumber,
      contactName: row.contactName,
      contactId: row.contactId,
      status: row.status,
      launchSuccess: row.launchSuccess == 1,
      failureReason: row.failureReason,
      attemptedAt: row.attemptedAt,
    );
  }

  static List<StagedRecipient> stagedToDomainList(
      List<db.StagedRecipient> rows) {
    return rows.map(stagedToDomain).toList();
  }

  static db.StagedRecipientsCompanion stagedToInsertCompanion(
    StagedRecipient recipient,
  ) {
    return db.StagedRecipientsCompanion.insert(
      id: recipient.id,
      sessionId: recipient.sessionId,
      phoneNumber: recipient.phoneNumber,
      contactName: recipient.contactName,
      contactId: Value(recipient.contactId),
      status: recipient.status,
      launchSuccess: recipient.launchSuccess ? 1 : 0,
      failureReason: Value(recipient.failureReason),
      attemptedAt: Value(recipient.attemptedAt),
    );
  }

  static db.StagedRecipientsCompanion stagedToUpdateCompanion(
    StagedRecipient recipient,
  ) {
    return db.StagedRecipientsCompanion(
      id: Value(recipient.id),
      status: Value(recipient.status),
      launchSuccess: Value(recipient.launchSuccess ? 1 : 0),
      failureReason: Value(recipient.failureReason),
      attemptedAt: Value(recipient.attemptedAt),
    );
  }

  static PreferredApp preferenceToDomain(db.WhatsAppPreferenceData row) {
    return PreferredApp(
      packageName: row.packageName,
      appName: row.appName,
      isSet: row.isSet == 1,
    );
  }

  static db.WhatsAppPreferenceCompanion preferenceToCompanion(
    PreferredApp app,
    String id,
    String tenantId,
  ) {
    return db.WhatsAppPreferenceCompanion.insert(
      id: id,
      tenantId: tenantId,
      packageName: app.packageName,
      appName: app.appName,
      isSet: app.isSet ? 1 : 0,
    );
  }

  static db.WhatsAppPreferenceCompanion preferenceToUpdateCompanion(
    PreferredApp app,
  ) {
    return db.WhatsAppPreferenceCompanion(
      packageName: Value(app.packageName),
      appName: Value(app.appName),
      isSet: Value(app.isSet ? 1 : 0),
    );
  }
}
