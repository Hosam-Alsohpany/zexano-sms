import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;

class WhatsAppLocalSource {
  final db.AppDatabase _database;

  WhatsAppLocalSource(this._database);

  Future<void> insertSession(db.AssistedSessionsCompanion companion) async {
    await _database.into(_database.assistedSessions).insert(companion);
  }

  Future<void> updateSession(db.AssistedSessionsCompanion companion) async {
    await (_database.update(_database.assistedSessions)
          ..where((t) => t.sessionId.equals(companion.sessionId.value)))
        .write(companion);
  }

  Future<db.AssistedSession?> getSessionById(String sessionId) async {
    return await (_database.select(_database.assistedSessions)
          ..where((t) => t.sessionId.equals(sessionId)))
        .getSingleOrNull();
  }

  Future<List<db.AssistedSession>> getSessions({
    int? limit,
    int? offset,
  }) async {
    final query = _database.select(_database.assistedSessions)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (limit != null) {
      query.limit(limit, offset: offset ?? 0);
    }
    return await query.get();
  }

  Future<void> insertStagedRecipient(
      db.StagedRecipientsCompanion companion) async {
    await _database.into(_database.stagedRecipients).insert(companion);
  }

  Future<void> batchInsertStagedRecipients(
    List<db.StagedRecipientsCompanion> companions,
  ) async {
    await _database.batch((batch) {
      batch.insertAll(_database.stagedRecipients, companions);
    });
  }

  Future<void> updateStagedRecipient(
      db.StagedRecipientsCompanion companion) async {
    await (_database.update(_database.stagedRecipients)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
  }

  Future<db.StagedRecipient?> getStagedRecipientById(String id) async {
    return await (_database.select(_database.stagedRecipients)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<db.StagedRecipient>> getStagedRecipientsBySession(
    String sessionId, {
    String? status,
  }) async {
    final query = _database.select(_database.stagedRecipients)
      ..where((t) => t.sessionId.equals(sessionId));
    if (status != null) {
      query.where((t) => t.status.equals(status));
    }
    return await query.get();
  }

  Future<List<db.StagedRecipient>> getPendingRecipients(
      String sessionId) async {
    return await (_database.select(_database.stagedRecipients)
          ..where((t) => t.sessionId.equals(sessionId))
          ..where((t) => t.status.equals('pending')))
        .get();
  }

  Future<int> countByStatus(String sessionId, String status) async {
    final query = _database.selectOnly(_database.stagedRecipients)
      ..addColumns([_database.stagedRecipients.id])
      ..where(_database.stagedRecipients.sessionId.equals(sessionId))
      ..where(_database.stagedRecipients.status.equals(status));
    return await query.get().then((r) => r.length);
  }

  Future<void> upsertPreference(db.WhatsAppPreferenceCompanion companion) async {
    await _database.into(_database.whatsAppPreference).insert(
      companion,
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<db.WhatsAppPreferenceData?> getPreference(String id) async {
    return await (_database.select(_database.whatsAppPreference)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }
}
