import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;

class HistoryLocalSource {
  final db.AppDatabase _database;

  HistoryLocalSource(this._database);

  Future<List<String>> listSmsBatchIds({
    int? limit,
    int? offset,
    String? direction, // null = all directions
  }) async {
    final query = _database.selectOnly(_database.messageHistory)
      ..addColumns([_database.messageHistory.batchId])
      ..addColumns([_database.messageHistory.timestamp])
      ..orderBy([OrderingTerm.desc(_database.messageHistory.timestamp)])
      ..groupBy([_database.messageHistory.batchId]);

    // Direction filter is now optional — null means all directions.
    // Pass 'outbound' explicitly when you want outbound-only.
    if (direction != null) {
      query.where(_database.messageHistory.direction.equals(direction));
    }

    if (limit != null) {
      query.limit(limit, offset: offset ?? 0);
    }

    final rows = await query.get();
    return rows
        .map((r) => r.read(_database.messageHistory.batchId)!)
        .toList();
  }

  /// Live stream of distinct batch IDs ordered by most-recent-first.
  ///
  /// **Why full rows instead of SELECT...GROUP BY:**
  /// Drift's stream deduplication compares successive query results by equality.
  /// A grouped query returns the same list of [batchId] strings even after
  /// [SmsSentReceiver] updates [executionStatus] inside an existing batch.
  /// Drift sees "same result → no re-emission" and the UI stays stale.
  ///
  /// By watching the full [messageHistory] rows we guarantee that ANY row
  /// mutation (status, sentAt, contactName…) produces a changed result set →
  /// Drift always re-emits → UI updates in real-time without user interaction.
  ///
  /// [direction]: null = all, 'outbound' = sent only, 'inbound' = received only.
  Stream<List<String>> watchSmsBatchIds({int? limit, String? direction}) {
    final sel = _database.select(_database.messageHistory);
    if (direction != null) {
      sel.where((t) => t.direction.equals(direction));
    }
    sel.orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return sel.watch().map((rows) {
      final seen = <String>{};
      final result = <String>[];
      for (final row in rows) {
        if (seen.add(row.batchId)) {
          result.add(row.batchId);
          if (limit != null && result.length >= limit) break;
        }
      }
      return result;
    });
  }

  /// Reactive stream of all rows in a specific batch, ordered by timestamp.
  ///
  /// Used by [HistoryRepositoryImpl.watchHistoryDetail] to power the Detail
  /// screen without subscribing to the entire [messageHistory] table.
  /// Only rows for [batchId] are watched — status updates from other batches
  /// do NOT trigger a rebuild.
  Stream<List<db.MessageHistoryData>> watchSmsBatchRows(String batchId) {
    return (_database.select(_database.messageHistory)
          ..where((t) => t.batchId.equals(batchId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .watch();
  }

  Future<List<db.MessageHistoryData>> getSmsBatchRows(String batchId) async {
    return await (_database.select(_database.messageHistory)
          ..where((t) => t.batchId.equals(batchId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Future<List<String>> listSmsBatchIdsByContact(String contactId) async {
    final rows = await (_database.selectOnly(_database.messageHistory)
          ..addColumns([_database.messageHistory.batchId])
          ..where(
              _database.messageHistory.contactId.equals(contactId))
          ..groupBy([_database.messageHistory.batchId]))
        .get();
    return rows
        .map((r) => r.read(_database.messageHistory.batchId)!)
        .toList();
  }

  Future<List<String>> searchSmsBatchIds(String query) async {
    final rows = await (_database.selectOnly(_database.messageHistory)
          ..addColumns([_database.messageHistory.batchId])
          ..where(
              _database.messageHistory.messageBody.contains(query))
          ..groupBy([_database.messageHistory.batchId]))
        .get();
    return rows
        .map((r) => r.read(_database.messageHistory.batchId)!)
        .toList();
  }

  Future<List<db.AssistedSession>> getWhatsAppSessions({
    int? limit,
    int? offset,
    String? status,
  }) async {
    final query = _database.select(_database.assistedSessions)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (status != null) {
      query.where((t) => t.status.equals(status));
    }
    if (limit != null) {
      query.limit(limit, offset: offset ?? 0);
    }

    return await query.get();
  }

  Future<List<db.AssistedSession>> searchWhatsAppSessions(
      String query) async {
    return await (_database.select(_database.assistedSessions)
          ..where((t) => t.messageBody.contains(query))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> deleteSmsBatch(String batchId) async {
    await (_database.delete(_database.messageHistory)
          ..where((t) => t.batchId.equals(batchId)))
        .go();
  }

  /// Deletes all rows for [batchIds] in a single atomic transaction.
  /// Invariant #13: 0 → no-op; N → one transaction, not N operations.
  Future<void> deleteSmsBatches(List<String> batchIds) async {
    if (batchIds.isEmpty) return;
    await _database.transaction(() async {
      await (_database.delete(_database.messageHistory)
            ..where((t) => t.batchId.isIn(batchIds)))
          .go();
    });
  }

  Future<void> deleteWhatsAppSession(String sessionId) async {
    await (_database.delete(_database.stagedRecipients)
          ..where((t) => t.sessionId.equals(sessionId)))
        .go();
    await (_database.delete(_database.assistedSessions)
          ..where((t) => t.sessionId.equals(sessionId)))
        .go();
  }

  /// Clears campaign rows only ('campaign' | 'group' source types).
  /// Does NOT delete single outbound messages or inbound messages.
  /// Using sourceType filter (not peerId IS NULL) because peerId is now mandatory.
  Future<int> clearSmsHistory() async {
    return await (_database.delete(_database.messageHistory)
          ..where((t) => t.sourceType.isIn(['campaign', 'group'])))
        .go();
  }

  Future<int> clearWhatsAppHistory() async {
    await _database.delete(_database.stagedRecipients).go();
    return await _database.delete(_database.assistedSessions).go();
  }

  // ── Group name resolution ────────────────────────────────────────────────────

  /// Returns the name of the group with [groupId], or null if the group does
  /// not exist (deleted) or [groupId] is empty.
  ///
  /// Returns only the [name] field so callers don't need to reference the
  /// generated [db.Group] type.
  Future<String?> getGroupName(String groupId) async {
    if (groupId.isEmpty) return null;
    final row = await (_database.select(_database.groups)
          ..where((t) => t.id.equals(groupId)))
        .getSingleOrNull();
    return row?.name;
  }
}
