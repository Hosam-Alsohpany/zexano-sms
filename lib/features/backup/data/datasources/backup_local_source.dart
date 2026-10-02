import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;

class BackupLocalSource {
  final db.AppDatabase _database;

  BackupLocalSource(this._database);

  Future<List<Map<String, dynamic>>> exportContacts() async {
    final rows = await _database.select(_database.contacts).get();
    return rows.map((r) => _contactToMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> exportGroups() async {
    final rows = await _database.select(_database.groups).get();
    return rows.map((r) => _groupToMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> exportGroupMembers() async {
    final rows = await _database.select(_database.groupMembers).get();
    return rows.map((r) => _groupMemberToMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> exportTags() async {
    final rows = await _database.select(_database.tags).get();
    return rows.map((r) => _tagToMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> exportContactTags() async {
    final rows = await _database.select(_database.contactTags).get();
    return rows.map((r) => _contactTagToMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> exportMessageTemplates() async {
    final rows = await _database.select(_database.messageTemplates).get();
    return rows.map((r) => _messageTemplateToMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> exportMessageHistory() async {
    final rows = await _database.select(_database.messageHistory).get();
    return rows.map((r) => _messageHistoryToMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> exportAssistedSessions() async {
    final rows = await _database.select(_database.assistedSessions).get();
    return rows.map((r) => _assistedSessionToMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> exportStagedRecipients() async {
    final rows = await _database.select(_database.stagedRecipients).get();
    return rows.map((r) => _stagedRecipientToMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> exportWhatsAppPreferences() async {
    final rows = await _database.select(_database.whatsAppPreference).get();
    return rows.map((r) => _whatsAppPreferenceToMap(r)).toList();
  }

  Future<void> importContacts(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.contacts).insert(
        db.ContactsCompanion.insert(
          id: row['id'] as String,
          tenantId: row['tenantId'] as String,
          firstName: row['firstName'] as String,
          lastName: row['lastName'] as String,
          phoneNumber: row['phoneNumber'] as String,
          normalizedPhone: row['normalizedPhone'] as String,
          operatorName: Value<String?>(row['operatorName'] as String),
          notes: Value<String?>(row['notes'] as String),
          isFavorite: (row['isFavorite'] as num).toInt(),
          createdAt: (row['createdAt'] as num).toInt(),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> importGroups(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.groups).insert(
        db.GroupsCompanion.insert(
          id: row['id'] as String,
          tenantId: row['tenantId'] as String,
          name: row['name'] as String,
          description: row['description'] as String,
          createdAt: (row['createdAt'] as num).toInt(),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> importGroupMembers(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.groupMembers).insert(
        db.GroupMembersCompanion.insert(
          groupId: row['groupId'] as String,
          contactId: row['contactId'] as String,
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> importTags(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.tags).insert(
        db.TagsCompanion.insert(
          id: row['id'] as String,
          tenantId: row['tenantId'] as String,
          name: row['name'] as String,
          createdAt: (row['createdAt'] as num).toInt(),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> importContactTags(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.contactTags).insert(
        db.ContactTagsCompanion.insert(
          contactId: row['contactId'] as String,
          tagId: row['tagId'] as String,
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> importMessageTemplates(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.messageTemplates).insert(
        db.MessageTemplatesCompanion.insert(
          id: row['id'] as String,
          tenantId: row['tenantId'] as String,
          title: row['title'] as String,
          bodyContent: row['bodyContent'] as String,
          createdAt: (row['createdAt'] as num).toInt(),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> importMessageHistory(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.messageHistory).insert(
        db.MessageHistoryCompanion.insert(
          id: row['id'] as String,
          tenantId: row['tenantId'] as String,
          batchId: row['batchId'] as String,
          contactName: row['contactName'] as String,
          contactId: row['contactId'] != null ? Value(row['contactId'] as String) : const Value.absent(),
          targetPhone: row['targetPhone'] as String,
          messageBody: row['messageBody'] as String,
          channelType: row['channelType'] as String,
          executionStatus: row['executionStatus'] as String,
          timestamp: (row['timestamp'] as num).toInt(),
          sentAt: row['sentAt'] != null ? Value((row['sentAt'] as num).toInt()) : const Value.absent(),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> importAssistedSessions(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.assistedSessions).insert(
        db.AssistedSessionsCompanion.insert(
          sessionId: row['sessionId'] as String,
          tenantId: row['tenantId'] as String,
          messageBody: row['messageBody'] as String,
          totalRecipients: (row['totalRecipients'] as num).toInt(),
          completedRecipients: (row['completedRecipients'] as num).toInt(),
          failedRecipients: (row['failedRecipients'] as num).toInt(),
          currentIndex: (row['currentIndex'] as num).toInt(),
          status: row['status'] as String,
          createdAt: (row['createdAt'] as num).toInt(),
          completedAt: row['completedAt'] != null ? Value((row['completedAt'] as num).toInt()) : const Value.absent(),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> importStagedRecipients(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.stagedRecipients).insert(
        db.StagedRecipientsCompanion.insert(
          id: row['id'] as String,
          sessionId: row['sessionId'] as String,
          phoneNumber: row['phoneNumber'] as String,
          contactName: row['contactName'] as String,
          contactId: row['contactId'] != null ? Value(row['contactId'] as String) : const Value.absent(),
          status: row['status'] as String,
          launchSuccess: (row['launchSuccess'] as num).toInt(),
          failureReason: row['failureReason'] != null ? Value(row['failureReason'] as String) : const Value.absent(),
          attemptedAt: row['attemptedAt'] != null ? Value((row['attemptedAt'] as num).toInt()) : const Value.absent(),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> importWhatsAppPreferences(
      List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      await _database.into(_database.whatsAppPreference).insert(
        db.WhatsAppPreferenceCompanion.insert(
          id: row['id'] as String,
          tenantId: row['tenantId'] as String,
          packageName: row['packageName'] as String,
          appName: row['appName'] as String,
          isSet: (row['isSet'] as num).toInt(),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<void> clearAllTables() async {
    await _database.delete(_database.stagedRecipients).go();
    await _database.delete(_database.assistedSessions).go();
    await _database.delete(_database.messageHistory).go();
    await _database.delete(_database.messageTemplates).go();
    await _database.delete(_database.groupMembers).go();
    await _database.delete(_database.groups).go();
    await _database.delete(_database.contactTags).go();
    await _database.delete(_database.tags).go();
    await _database.delete(_database.contacts).go();
  }

  Future<void> runInTransaction(Future<void> Function() fn) async {
    await _database.transaction(() async {
      await _database.customStatement('PRAGMA foreign_keys = OFF');
      try {
        await fn();
      } finally {
        await _database.customStatement('PRAGMA foreign_keys = ON');
      }
    });
  }

  Map<String, dynamic> _contactToMap(db.Contact r) => {
    'id': r.id,
    'tenantId': r.tenantId,
    'firstName': r.firstName,
    'lastName': r.lastName,
    'phoneNumber': r.phoneNumber,
    'normalizedPhone': r.normalizedPhone,
    'operatorName': r.operatorName,
    'notes': r.notes,
    'isFavorite': r.isFavorite,
    'createdAt': r.createdAt,
  };

  Map<String, dynamic> _groupToMap(db.Group r) => {
    'id': r.id,
    'tenantId': r.tenantId,
    'name': r.name,
    'description': r.description,
    'createdAt': r.createdAt,
  };

  Map<String, dynamic> _groupMemberToMap(db.GroupMember r) => {
    'groupId': r.groupId,
    'contactId': r.contactId,
  };

  Map<String, dynamic> _tagToMap(db.Tag r) => {
    'id': r.id,
    'tenantId': r.tenantId,
    'name': r.name,
    'createdAt': r.createdAt,
  };

  Map<String, dynamic> _contactTagToMap(db.ContactTag r) => {
    'contactId': r.contactId,
    'tagId': r.tagId,
  };

  Map<String, dynamic> _messageTemplateToMap(db.MessageTemplate r) => {
    'id': r.id,
    'tenantId': r.tenantId,
    'title': r.title,
    'bodyContent': r.bodyContent,
    'createdAt': r.createdAt,
  };

  Map<String, dynamic> _messageHistoryToMap(db.MessageHistoryData r) => {
    'id': r.id,
    'tenantId': r.tenantId,
    'batchId': r.batchId,
    'contactName': r.contactName,
    'contactId': r.contactId,
    'targetPhone': r.targetPhone,
    'messageBody': r.messageBody,
    'channelType': r.channelType,
    'executionStatus': r.executionStatus,
    'timestamp': r.timestamp,
    'sentAt': r.sentAt,
  };

  Map<String, dynamic> _assistedSessionToMap(db.AssistedSession r) => {
    'sessionId': r.sessionId,
    'tenantId': r.tenantId,
    'messageBody': r.messageBody,
    'totalRecipients': r.totalRecipients,
    'completedRecipients': r.completedRecipients,
    'failedRecipients': r.failedRecipients,
    'currentIndex': r.currentIndex,
    'status': r.status,
    'createdAt': r.createdAt,
    'completedAt': r.completedAt,
  };

  Map<String, dynamic> _stagedRecipientToMap(db.StagedRecipient r) => {
    'id': r.id,
    'sessionId': r.sessionId,
    'phoneNumber': r.phoneNumber,
    'contactName': r.contactName,
    'contactId': r.contactId,
    'status': r.status,
    'launchSuccess': r.launchSuccess,
    'failureReason': r.failureReason,
    'attemptedAt': r.attemptedAt,
  };

  Map<String, dynamic> _whatsAppPreferenceToMap(db.WhatsAppPreferenceData r) => {
    'id': r.id,
    'tenantId': r.tenantId,
    'packageName': r.packageName,
    'appName': r.appName,
    'isSet': r.isSet,
  };
}
