import 'package:drift/drift.dart';
import 'package:zexano_sms/core/database/local_database.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

class SmsLocalSource {
  final AppDatabase _db;
  final NormalizationEngine _normalizationEngine;

  SmsLocalSource(this._db, this._normalizationEngine);

  // ── Stream notification (no redundant writes) ───────────────────────────────

  /// Notifies Drift that [messageHistory] changed externally (e.g. written by
  /// [SmsSentReceiver] directly via SQLite).  All active `.watch()` queries
  /// re-read the table — no data is written, DB remains the Source of Truth.
  ///
  /// Prefer this over [updateStatusById] when the row is already correct and
  /// only the Drift stream notification is needed.
  void notifyMessageHistoryUpdated() {
    _db.markTablesUpdated({_db.messageHistory});
  }

  Future<void> deleteHistoryRowsByIds(List<String> ids) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      await (_db.delete(_db.messageHistory)..where((t) => t.id.isIn(ids))).go();
    });
  }

  // ── Insert / Batch ──────────────────────────────────────────────────────────

  Future<void> insertHistoryRow(MessageHistoryCompanion companion) async {
    await _db.into(_db.messageHistory).insert(companion);
  }

  Future<void> batchInsertHistoryRows(
    List<MessageHistoryCompanion> companions,
  ) async {
    await _db.batch((batch) {
      batch.insertAll(_db.messageHistory, companions);
    });
  }

  /// Inserts an inbound SMS row received from [SmsReceiver] / EventChannel.
  /// [contactName] is null when the sender is not in contacts — the UI
  /// will display the raw phone number in that case.
  Future<void> insertInboundMessage({
    required String id,
    required String tenantId,
    required String senderPhone,
    required String body,
    required int receivedAtSeconds,
    String? contactName,
    String? contactId,
  }) async {
    final companion = _buildInboundCompanion(
      id: id,
      tenantId: tenantId,
      senderPhone: senderPhone,
      body: body,
      receivedAtSeconds: receivedAtSeconds,
      contactName: contactName,
      contactId: contactId,
    );
    await _db.into(_db.messageHistory).insert(companion);
  }

  /// Two-phase idempotent inbound write used by [IncomingSmsService].
  ///
  /// **Phase 1 — INSERT OR IGNORE:**
  /// Idempotent by PK. If native already wrote the row this is a no-op;
  /// if native failed, this inserts the row.
  ///
  /// **Phase 2 — Stream notification + optional contact enrichment:**
  ///
  /// | Path | Contact found? | Action |
  /// |------|---------------|--------|
  /// | INSERT | yes | UPDATE contact fields (real data → triggers streams) |
  /// | INSERT | no  | nothing — Drift already fired streams via the INSERT |
  /// | IGNORE | yes | UPDATE contact fields (enriches native row + triggers streams) |
  /// | IGNORE | no  | `markTablesUpdated` — zero writes, streams fire, DB is Source of Truth |
  ///
  /// **contactName protection:** An incoming null/empty name NEVER overwrites a
  /// non-empty name already stored in the DB. This prevents a race where a
  /// duplicate event (no contact data) clobbers the enriched row written by the
  /// first event.
  ///
  /// Returns `true` if a new row was inserted, `false` if IGNORE was taken.
  Future<bool> insertInboundMessageOrIgnore({
    required String id,
    required String tenantId,
    required String senderPhone,
    required String body,
    required int receivedAtSeconds,
    String? contactName,
    String? contactId,
  }) async {
    // ── Phase 1: idempotent insert ─────────────────────────────────────────
    final companion = _buildInboundCompanion(
      id: id,
      tenantId: tenantId,
      senderPhone: senderPhone,
      body: body,
      receivedAtSeconds: receivedAtSeconds,
      contactName: contactName,
      contactId: contactId,
    );
    final rowId = await _db
        .into(_db.messageHistory)
        .insert(companion, mode: InsertMode.insertOrIgnore);
    final inserted = rowId != 0; // false = IGNORE branch taken

    // ── Phase 2: stream notification + contact enrichment ──────────────────
    final hasContactData =
        contactId != null || (contactName != null && contactName.isNotEmpty);

    if (hasContactData) {
      // Read existing row to honour contactName protection rule.
      final existing = await (_db.select(_db.messageHistory)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();

      // Never overwrite a non-empty stored name with an empty/null incoming one.
      final safeName = (contactName != null && contactName.isNotEmpty)
          ? contactName
          : (existing?.contactName ?? '');

      await (_db.update(_db.messageHistory)..where((t) => t.id.equals(id)))
          .write(
        MessageHistoryCompanion(
          contactName: Value(safeName),
          contactId: Value(contactId),
        ),
      );
    } else if (!inserted) {
      // IGNORE path + no contact data: nothing genuine to write.
      _db.markTablesUpdated({_db.messageHistory});
    }
    // INSERT path + no contact: Drift already notified streams via the INSERT.

    return inserted;
  }

  /// Shared builder to ensure both inbound insert methods produce identical rows.
  /// [peerId] is computed here using the same NormalizationEngine used by Kotlin
  /// so that inbound and outbound messages share the same Conversation.
  MessageHistoryCompanion _buildInboundCompanion({
    required String id,
    required String tenantId,
    required String senderPhone,
    required String body,
    required int receivedAtSeconds,
    String? contactName,
    String? contactId,
  }) {
    // Normalize to canonical form then build peerId.
    // Must match NormalizationEngine.kt + generatePeerId() on the Kotlin side.
    final normalizedPhone = _normalizationEngine.normalize(senderPhone);
    final isAlphanumericSender = normalizedPhone.isEmpty;
    final String? peerId = isAlphanumericSender ? null : 'sms:$normalizedPhone';
    final String sourceType = isAlphanumericSender ? 'inbound_alpha' : 'inbound';

    return MessageHistoryCompanion.insert(
      id: id,
      tenantId: tenantId,
      batchId: id, // each inbound is its own "batch"
      contactName: contactName ?? '',
      contactId: Value(contactId),
      targetPhone: senderPhone,
      messageBody: body,
      channelType: 'sms',
      executionStatus: 'received',
      timestamp: receivedAtSeconds,
      sourceType: Value(sourceType), // 'inbound_alpha' -> no Conversation row created
      direction: const Value('inbound'),
      receivedAt: Value(receivedAtSeconds),
      peerId: Value(peerId),
    );
  }

  // ── Queries ─────────────────────────────────────────────────────────────────

  Future<List<MessageHistoryData>> getBatchRows(String batchId) async {
    return await (_db.select(_db.messageHistory)
          ..where((t) => t.batchId.equals(batchId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  Future<List<MessageHistoryData>> getHistoryRows({
    int? limit,
    int? offset,
    String? channelType,
  }) async {
    final query = _db.select(_db.messageHistory)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);

    if (channelType != null) {
      query.where((t) => t.channelType.equals(channelType));
    }
    if (limit != null) {
      query.limit(limit, offset: offset ?? 0);
    }

    return await query.get();
  }

  Future<List<String>> listBatchIds({
    int? limit,
    int? offset,
    String? channelType,
  }) async {
    final query = _db.selectOnly(_db.messageHistory)
      ..addColumns([_db.messageHistory.batchId])
      ..orderBy([OrderingTerm.desc(_db.messageHistory.timestamp)]);

    if (channelType != null) {
      query.where(_db.messageHistory.channelType.equals(channelType));
    }

    query.groupBy([_db.messageHistory.batchId]);

    if (limit != null) {
      query.limit(limit, offset: offset ?? 0);
    }

    final rows = await query.get();
    return rows
        .map((r) => r.read(_db.messageHistory.batchId)!)
        .toList();
  }

  Future<List<MessageHistoryData>> getFailedRowsForBatch(String batchId) async {
    return await (_db.select(_db.messageHistory)
          ..where(
            (t) =>
                t.batchId.equals(batchId) &
                t.executionStatus.equals('failed'),
          ))
        .get();
  }

  /// Atomically claims failed rows for retry.
  ///
  /// **Invariants #5, #6, #7, #8:**
  ///   - Only rows with `executionStatus == 'failed'` are eligible.
  ///   - `delivered`, `sent`, `received`, `queued`, `sending` are NEVER retried.
  ///   - Uses a single DB transaction: SELECT → UPDATE → return claimed rows.
  ///   - If another process already updated the row away from 'failed',
  ///     the UPDATE matches 0 rows → that row is NOT returned → no duplicate send.
  ///   - Rapid double-tap: second call finds no 'failed' rows → returns empty.
  ///
  /// [batchId] is the batch to retry. Only failed rows in this batch are claimed.
  Future<List<MessageHistoryData>> claimFailedRowsForRetry(
    String batchId,
  ) async {
    return _db.transaction<List<MessageHistoryData>>(() async {
      // Step 1: SELECT failed rows in this batch.
      final candidates = await (_db.select(_db.messageHistory)
            ..where(
              (t) =>
                  t.batchId.equals(batchId) &
                  t.executionStatus.equals('failed'),
            ))
          .get();

      if (candidates.isEmpty) return [];

      // Step 2: Atomically UPDATE each candidate from 'failed' → 'queued'.
      // The WHERE clause re-checks executionStatus == 'failed' inside the
      // transaction — if any row was updated by another process first,
      // the update count is 0 and we skip that row.
      final claimed = <MessageHistoryData>[];
      for (final row in candidates) {
        final updatedCount = await (_db.update(_db.messageHistory)
              ..where(
                (t) =>
                    t.id.equals(row.id) &
                    t.executionStatus.equals('failed'), // re-check atomically
              ))
            .write(
          const MessageHistoryCompanion(
            executionStatus: Value('queued'),
          ),
        );
        // Only include row if the UPDATE actually matched (count > 0).
        if (updatedCount > 0) claimed.add(row);
      }

      return claimed;
    });
  }

  Future<List<MessageHistoryData>> getFailedRowsForRetry({
    int? limit,
  }) async {
    final query = _db.select(_db.messageHistory)
      ..where((t) => t.executionStatus.equals('failed'))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);

    if (limit != null) {
      query.limit(limit);
    }

    return await query.get();
  }

  /// Returns all messages (inbound + outbound) for a given normalised phone
  /// ordered by timestamp ascending — for future Thread/conversation view.
  Future<List<MessageHistoryData>> getMessagesForPhone(String phone) async {
    return await (_db.select(_db.messageHistory)
          ..where((t) => t.targetPhone.equals(phone))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  // ── Status Updates ───────────────────────────────────────────────────────────

  /// Updates a single row by [id] — primary method for delivery-status updates.
  Future<void> updateStatusById(
    String id,
    String status, {
    int? sentAt,
  }) async {
    final companion = MessageHistoryCompanion(
      executionStatus: Value(status),
      sentAt: sentAt != null ? Value(sentAt) : const Value.absent(),
    );
    await (_db.update(_db.messageHistory)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Alias kept for backwards compatibility with existing call-sites.
  Future<void> updateHistoryRowStatus(
    String id,
    String status, {
    int? sentAt,
  }) =>
      updateStatusById(id, status, sentAt: sentAt);

  /// Priority table sourced from [MessageStatusService.statusPriority].
  ///
  /// Kept as a local reference for zero-overhead access (avoids map lookup
  /// on every call). The canonical definition lives in [MessageStatusService].
  static final Map<String, int> _statusPriority =
      MessageStatusService.statusPriority;

  /// Safe version of [updateStatusById] that respects both priority AND
  /// the State Transition Map from [MessageStatusService.canTransition].
  ///
  /// A write is skipped when either:
  ///   a) [status] has lower priority than the current status, OR
  ///   b) The transition is semantically invalid (e.g. delivered → queued).
  Future<void> updateStatusByIdSafe(
    String id,
    String status, {
    int? sentAt,
  }) async {
    final existing = await (_db.select(_db.messageHistory)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing == null) return;

    final currentStatus = existing.executionStatus;
    final currentPriority = _statusPriority[currentStatus] ?? 0;
    final newPriority = _statusPriority[status] ?? 0;

    // Reject if lower priority.
    if (newPriority < currentPriority) return;

    // Reject if transition is not allowed by the State Transition Map.
    if (!MessageStatusService.canTransition(currentStatus, status,
        direction: existing.direction)) return;

    await updateStatusById(id, status, sentAt: sentAt);
  }

  Future<void> updateBatchStatuses(
    List<String> ids,
    String status, {
    int? sentAt,
  }) async {
    // Safe batch update: applies the same priority + transition checks
    // per individual row — avoids a late 'queued' broadcast overwriting
    // rows already in 'sent' or 'delivered' state.
    for (final id in ids) {
      await updateStatusByIdSafe(id, status, sentAt: sentAt);
    }
  }

  // ── Batch Deletion ────────────────────────────────────────────────────────

  /// Deletes all [MessageHistory] rows for the given batch IDs in a single
  /// atomic transaction.
  ///
  /// **Invariant #13:** Batch deletion is a single transaction.
  ///   - 0 IDs → no-op
  ///   - 1 ID → same path as N IDs
  ///   - N IDs → one transaction, all-or-nothing
  Future<void> deleteSmsBatches(List<String> batchIds) async {
    if (batchIds.isEmpty) return;
    await _db.transaction(() async {
      await (_db.delete(_db.messageHistory)
            ..where((t) => t.batchId.isIn(batchIds)))
          .go();
    });
  }

  // ── Templates ─────────────────────────────────────────────────────────────────

  Future<List<MessageTemplate>> getAllTemplates() async {
    return await (_db.select(_db.messageTemplates)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<MessageTemplate?> getTemplateById(String id) async {
    return await (_db.select(_db.messageTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertTemplate(MessageTemplatesCompanion companion) async {
    await _db.into(_db.messageTemplates).insert(companion);
  }

  Future<void> updateTemplate(MessageTemplatesCompanion companion) async {
    await (_db.update(_db.messageTemplates)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
  }

  Future<void> deleteTemplate(String id) async {
    await (_db.delete(_db.messageTemplates)..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Contacts helpers ─────────────────────────────────────────────────────────

  Future<Contact?> getContactById(String id) async {
    return await (_db.select(_db.contacts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Contact>> getContactsByIds(List<String> ids) async {
    return await (_db.select(_db.contacts)
          ..where((t) => t.id.isIn(ids)))
        .get();
  }

  Future<Contact?> getContactByPhone(String normalizedPhone) async {
    return await (_db.select(_db.contacts)
          ..where((t) => t.normalizedPhone.equals(normalizedPhone)))
        .getSingleOrNull();
  }

  Future<Contact?> getContactByAnyPhone(String phone) async {
    return await (_db.select(_db.contacts)
          ..where((t) =>
              t.normalizedPhone.equals(phone) |
              t.phoneNumber.equals(phone)))
        .getSingleOrNull();
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    return await (_db.select(_db.groupMembers)
          ..where((t) => t.groupId.equals(groupId)))
        .get();
  }

  // ── Inbound name enrichment helpers ───────────────────────────────────────

  /// Returns all inbound rows where `contact_name` is empty (`''`).
  ///
  /// Used by [ContactIdentityResolver.backfillInboundNames] on startup to
  /// enrich rows written by Kotlin (which always stores `contactName = ""`).
  /// Only inbound rows are eligible — outbound rows are not affected.
  Future<List<MessageHistoryData>> getInboundRowsWithEmptyName() async {
    return await (_db.select(_db.messageHistory)
          ..where(
            (t) =>
                t.direction.equals('inbound') &
                t.contactName.equals(''),
          ))
        .get();
  }

  /// Updates the `contact_name` and `contact_id` for an inbound row.
  ///
  /// Used by [ContactIdentityResolver.enrichInboundName] after resolving a
  /// contact from the Contacts table. Also fires Drift stream notifications
  /// so active watchers (History, Conversations) update immediately.
  Future<void> updateInboundContactName({
    required String rowId,
    required String contactName,
    String? contactId,
  }) async {
    await (_db.update(_db.messageHistory)..where((t) => t.id.equals(rowId)))
        .write(
      MessageHistoryCompanion(
        contactName: Value(contactName),
        contactId: Value(contactId),
      ),
    );
  }
}

