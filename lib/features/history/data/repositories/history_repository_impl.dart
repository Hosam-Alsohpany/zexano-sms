import 'package:dartz/dartz.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/features/history/data/datasources/history_local_source.dart';
import 'package:zexano_sms/features/history/data/mappers/history_mapper.dart';
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';
import 'package:zexano_sms/features/history/domain/models/grouped_timeline_result.dart';
import 'package:zexano_sms/features/history/domain/models/history_detail_projection.dart';
import 'package:zexano_sms/features/history/domain/models/recipient_detail.dart';
import 'package:zexano_sms/features/history/domain/models/retryable_action_hint.dart';
import 'package:zexano_sms/features/history/domain/repositories/history_repository.dart';
import 'package:zexano_sms/features/history/domain/value_objects/history_filter.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/shared/contact_identity_resolver.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalSource _localSource;
  final ContactIdentityResolver? _identityResolver;
  final String _defaultTenantId;

  HistoryRepositoryImpl({
    required HistoryLocalSource localSource,
    ContactIdentityResolver? identityResolver,
    String defaultTenantId = 'default-tenant',
  })  : _localSource = localSource,
        _identityResolver = identityResolver,
        _defaultTenantId = defaultTenantId;

  @override
  Future<AppResult<List<HistoryEntry>>> listMessageHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final entries = await _fetchCombinedHistory(
        smsLimit: limit,
        smsOffset: offset,
        waLimit: limit,
        waOffset: offset,
      );
      return Right(entries);
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to list message history: ${e.toString()}',
        code: 'HISTORY_LIST_ERR',
      ));
    }
  }

  @override
  Stream<List<HistoryEntry>> watchMessageHistory() {
    // Delegates to Drift's .watch() on messageHistory (all directions).
    // Re-emits whenever any write touches the table.
    return _localSource.watchSmsBatchIds().asyncMap((batchIds) async {
      final smsEntries = await _batchIdsToEntries(batchIds);
      final waEntries = await _fetchWaEntries();
      return _mergeAndSort(smsEntries, waEntries);
    });
  }

  /// Reactive detail stream for a specific entry.
  ///
  /// For SMS: watches ONLY the rows belonging to [id]'s batchId — changes in
  /// other batches do NOT trigger a rebuild. This is more efficient than
  /// subscribing to the full [watchMessageHistory] stream.
  ///
  /// For WA: wraps [getHistoryDetail] in a one-shot stream (WA sessions do
  /// not change in real-time via the same mechanism).
  @override
  Stream<AppResult<HistoryDetailProjection>> watchHistoryDetail(String id) {
    if (id.startsWith('sms_')) {
      final batchId = id.substring(4);
      return _localSource.watchSmsBatchRows(batchId).asyncMap((rows) async {
        if (rows.isEmpty) {
          return Left<Failure, HistoryDetailProjection>(DatabaseFailure(
            message: 'Batch not found: $batchId',
            code: 'HISTORY_DETAIL_NOT_FOUND',
          ));
        }
        try {
          return Right(await _buildSmsDetailProjection(id, batchId, rows));
        } on Exception catch (e) {
          return Left(DatabaseFailure(
            message: 'Failed to build detail: $e',
            code: 'HISTORY_DETAIL_BUILD_ERR',
          ));
        }
      });
    }
    // WhatsApp: one-shot stream.
    return Stream.fromFuture(getHistoryDetail(id));
  }

  @override
  Future<AppResult<HistoryEntry?>> getHistoryEntryById(String id) async {
    try {
      if (id.startsWith('sms_')) {
        final batchId = id.substring(4);
        final rows = await _localSource.getSmsBatchRows(batchId);
        if (rows.isEmpty) return const Right(null);

        // Resolve group name if applicable.
        String? groupName;
        final groupId = rows.first.groupId;
        if (groupId != null && groupId.isNotEmpty) {
          groupName = await _localSource.getGroupName(groupId);
        }

        return Right(HistoryMapper.smsBatchToHistoryEntry(
          batchId: batchId,
          tenantId: _defaultTenantId,
          rows: rows,
          groupName: groupName,
        ));
      } else if (id.startsWith('wa_')) {
        final sessionId = id.substring(3);
        final sessions = await _localSource.getWhatsAppSessions();
        final session =
            sessions.where((s) => s.sessionId == sessionId).firstOrNull;
        if (session == null) return const Right(null);
        return Right(HistoryMapper.whatsAppSessionToHistoryEntry(
          row: session,
          tenantId: _defaultTenantId,
        ));
      }
      return const Right(null);
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get history entry: ${e.toString()}',
        code: 'HISTORY_GET_ERR',
      ));
    }
  }

  @override
  Future<AppResult<List<HistoryEntry>>> searchMessageHistory(
    String query, {
    int? limit,
    int? offset,
  }) async {
    try {
      final smsBatchIds = await _localSource.searchSmsBatchIds(query);
      final smsEntries = await _batchIdsToEntries(smsBatchIds);

      final waSessions = await _localSource.searchWhatsAppSessions(query);
      final waEntries = waSessions
          .map((s) => HistoryMapper.whatsAppSessionToHistoryEntry(
              row: s, tenantId: _defaultTenantId))
          .toList();

      final merged = _mergeAndSort(smsEntries, waEntries);
      return Right(_applyPagination(merged, limit: limit, offset: offset));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to search history: ${e.toString()}',
        code: 'HISTORY_SEARCH_ERR',
      ));
    }
  }

  @override
  Future<AppResult<List<HistoryEntry>>> filterHistoryByChannel(
    String channelType, {
    int? limit,
    int? offset,
  }) async {
    try {
      if (channelType == 'sms') {
        return Right(await _fetchSmsEntries(limit: limit, offset: offset));
      } else if (channelType == 'whatsapp') {
        return Right(await _fetchWaEntries(limit: limit, offset: offset));
      }
      return Right(await _fetchCombinedHistory(
        smsLimit: limit,
        smsOffset: offset,
        waLimit: limit,
        waOffset: offset,
      ));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to filter by channel: ${e.toString()}',
        code: 'HISTORY_CHANNEL_ERR',
      ));
    }
  }

  @override
  Future<AppResult<List<HistoryEntry>>> filterHistoryByStatus(
    String status, {
    int? limit,
    int? offset,
  }) async {
    try {
      final allEntries = await _fetchCombinedHistory();
      final filtered =
          allEntries.where((e) => e.status == status).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(_applyPagination(filtered, limit: limit, offset: offset));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to filter by status: ${e.toString()}',
        code: 'HISTORY_STATUS_ERR',
      ));
    }
  }

  @override
  Future<AppResult<List<HistoryEntry>>> filterHistoryByDateRange({
    required int dateFrom,
    required int dateTo,
    int? limit,
    int? offset,
  }) async {
    try {
      final allEntries = await _fetchCombinedHistory();
      final filtered = allEntries
          .where((e) => e.createdAt >= dateFrom && e.createdAt <= dateTo)
          .toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(
          _applyPagination(filtered, limit: limit, offset: offset));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to filter by date range: ${e.toString()}',
        code: 'HISTORY_DATE_ERR',
      ));
    }
  }

  @override
  Future<AppResult<List<HistoryEntry>>> filterHistoryByContact(
    String contactId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final batchIds =
          await _localSource.listSmsBatchIdsByContact(contactId);
      final smsEntries = await _batchIdsToEntries(batchIds);
      smsEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(
          _applyPagination(smsEntries, limit: limit, offset: offset));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to filter by contact: ${e.toString()}',
        code: 'HISTORY_CONTACT_ERR',
      ));
    }
  }

  @override
  Future<AppResult<List<HistoryEntry>>> filterHistoryByGroupContext(
    String groupId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final smsEntries = await _fetchSmsEntries();
      final groupEntries = smsEntries
          .where((e) => e.contactName != null || e.phoneNumber != null)
          .toList();
      groupEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(
          _applyPagination(groupEntries, limit: limit, offset: offset));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to filter by group context: ${e.toString()}',
        code: 'HISTORY_GROUP_ERR',
      ));
    }
  }

  @override
  Future<AppResult<List<HistoryEntry>>> listRecentHistory({
    int? limit,
    int? offset,
  }) async {
    return listMessageHistory(limit: limit ?? 20, offset: offset);
  }

  @override
  Future<AppResult<List<HistoryEntry>>> listHistoryForContact(
    String contactId, {
    int? limit,
    int? offset,
  }) async {
    return filterHistoryByContact(contactId, limit: limit, offset: offset);
  }

  @override
  Future<AppResult<List<HistoryEntry>>> listFailedHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final allEntries = await _fetchCombinedHistory();
      final failed = allEntries
          .where((e) =>
              e.failedCount > 0 &&
              e.status != 'completed' &&
              e.status != 'cancelled')
          .toList();
      failed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(_applyPagination(failed, limit: limit, offset: offset));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to list failed history: ${e.toString()}',
        code: 'HISTORY_FAILED_ERR',
      ));
    }
  }

  @override
  Future<AppResult<List<HistoryEntry>>> listRetryableHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final allEntries = await _fetchCombinedHistory();
      final retryable = allEntries
          .where((e) =>
              e.failedCount > 0 && e.channelType == 'sms' &&
              (e.status == 'failed' || e.status == 'partial'))
          .toList();
      retryable.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(
          _applyPagination(retryable, limit: limit, offset: offset));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to list retryable history: ${e.toString()}',
        code: 'HISTORY_RETRY_ERR',
      ));
    }
  }

  @override
  Future<AppResult<bool>> deleteHistoryEntry(String id) async {
    try {
      if (id.startsWith('sms_')) {
        final batchId = id.substring(4);
        await _localSource.deleteSmsBatch(batchId);
        return const Right(true);
      } else if (id.startsWith('wa_')) {
        final sessionId = id.substring(3);
        await _localSource.deleteWhatsAppSession(sessionId);
        return const Right(true);
      }
      return const Right(false);
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to delete history entry: ${e.toString()}',
        code: 'HISTORY_DELETE_ERR',
      ));
    }
  }

  /// Invariant #13: Deletes N history entries in a single atomic transaction.
  ///
  /// [ids] uses the prefixed form (`sms_<batchId>` or `wa_<sessionId>`).
  /// Strips the prefix, routes to the correct backend, single transaction.
  Future<AppResult<int>> deleteHistoryEntries(List<String> ids) async {
    if (ids.isEmpty) return const Right(0);
    try {
      final smsBatchIds = ids
          .where((id) => id.startsWith('sms_'))
          .map((id) => id.substring(4))
          .toList();
      final waSessionIds = ids
          .where((id) => id.startsWith('wa_'))
          .map((id) => id.substring(3))
          .toList();

      int deletedCount = 0;
      if (smsBatchIds.isNotEmpty) {
        // deleteSmsBatches uses a single transaction internally (Invariant #13)
        await _localSource.deleteSmsBatches(smsBatchIds);
        deletedCount += smsBatchIds.length;
      }
      if (waSessionIds.isNotEmpty) {
        for (final sessionId in waSessionIds) {
          await _localSource.deleteWhatsAppSession(sessionId);
          deletedCount++;
        }
      }
      return Right(deletedCount);
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to batch delete history entries: ${e.toString()}',
        code: 'HISTORY_BATCH_DELETE_ERR',
      ));
    }
  }


  Future<AppResult<int>> clearHistory({String? channelType}) async {
    try {
      int deletedCount = 0;
      if (channelType == null || channelType == 'sms') {
        deletedCount += await _localSource.clearSmsHistory();
      }
      if (channelType == null || channelType == 'whatsapp') {
        deletedCount += await _localSource.clearWhatsAppHistory();
      }
      return Right(deletedCount);
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to clear history: ${e.toString()}',
        code: 'HISTORY_CLEAR_ERR',
      ));
    }
  }

  @override
  Future<AppResult<List<GroupedTimelineResult>>> buildGroupedTimeline({
    HistoryFilter? filter,
  }) async {
    try {
      List<HistoryEntry> entries;

      if (filter != null) {
        if (filter.channelType != null) {
          final result = await filterHistoryByChannel(filter.channelType!);
          entries = result.getOrElse(() => []);
        } else {
          entries = await _fetchCombinedHistory();
        }

        if (filter.dateFrom != null && filter.dateTo != null) {
          entries = entries
              .where((e) =>
                  e.createdAt >= filter.dateFrom! &&
                  e.createdAt <= filter.dateTo!)
              .toList();
        } else if (filter.dateFrom != null) {
          entries = entries
              .where((e) => e.createdAt >= filter.dateFrom!)
              .toList();
        } else if (filter.dateTo != null) {
          entries = entries
              .where((e) => e.createdAt <= filter.dateTo!)
              .toList();
        }

        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          final q = filter.searchQuery!.toLowerCase();
          entries = entries
              .where((e) => e.messageBody.toLowerCase().contains(q))
              .toList();
        }

        if (filter.status != null) {
          entries = entries
              .where((e) => e.status == filter.status)
              .toList();
        }
      } else {
        entries = await _fetchCombinedHistory();
      }

      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final grouped = <String, List<HistoryEntry>>{};
      for (final entry in entries) {
        final label = _epochToDateLabel(entry.createdAt);
        grouped.putIfAbsent(label, () => []).add(entry);
      }

      final result = grouped.entries.map((g) {
        return GroupedTimelineResult(
          dateLabel: g.key,
          entries: g.value,
        );
      }).toList();

      result.sort((a, b) => b.dateLabel.compareTo(a.dateLabel));

      return Right(result);
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to build grouped timeline: ${e.toString()}',
        code: 'HISTORY_TIMELINE_ERR',
      ));
    }
  }

  @override
  Future<AppResult<HistoryDetailProjection>> getHistoryDetail(
      String id) async {
    try {
      final entryResult = await getHistoryEntryById(id);
      if (entryResult.isLeft()) {
        return Left(entryResult.swap().getOrElse(
              () => const DatabaseFailure(
                  message: 'Entry not found', code: 'HISTORY_DETAIL_ERR'),
            ));
      }
      final entry = entryResult.getOrElse(() => null);
      if (entry == null) {
        return Left(DatabaseFailure(
          message: 'History entry not found: $id',
          code: 'HISTORY_DETAIL_NOT_FOUND',
        ));
      }

      List<RecipientDetail> recipients = [];
      String? channelNotes;

      if (id.startsWith('sms_')) {
        final batchId = id.substring(4);
        final rows = await _localSource.getSmsBatchRows(batchId);

        // Build per-recipient list with individual status + sentAt timestamp.
        // Sort: sent/delivered → failed → queued.
        const statusOrder = {
          'sent': 0, 'delivered': 0,
          'failed': 1,
          'queued': 2, 'sending': 2,
        };
        final resolver = _identityResolver ??
            (sl.isRegistered<ContactIdentityResolver>()
                ? sl<ContactIdentityResolver>()
                : null);
        final allRecipients = await Future.wait(rows.map((r) async {
          String name = r.contactName;
          if ((name.isEmpty || name == r.targetPhone) && resolver != null) {
            name = await resolver.resolveName(
              phoneOrSender: r.targetPhone,
              storedName: r.contactName,
            );
          }
          if (name.isEmpty) name = r.targetPhone;
          return RecipientDetail(
            name: name,
            phone: r.targetPhone,
            status: r.executionStatus,
            updatedAt: r.sentAt,
            messageId: r.id,
            peerId: r.peerId,
          );
        }));
        allRecipients.sort((a, b) =>
            (statusOrder[a.status] ?? 3).compareTo(statusOrder[b.status] ?? 3));

        recipients = allRecipients;

        // Count using MessageStatusService — 'delivered' is a success.
        final sentCount = rows
            .where((r) => MessageStatusService.isSuccess(r.executionStatus))
            .length;
        final failedCount = rows
            .where((r) => MessageStatusService.isFailed(r.executionStatus))
            .length;
        final queuedCount = rows
            .where((r) => MessageStatusService.isPending(r.executionStatus))
            .length;
        if (rows.length > 1) {
          channelNotes =
              'SMS: $sentCount ✓ · $failedCount ✗ · $queuedCount ⏳';
        }
      } else if (id.startsWith('wa_')) {
        channelNotes =
            'WhatsApp: ${entry.successCount}/${entry.totalRecipients} completed';
      }

      return Right(HistoryDetailProjection(
        entry: entry,
        recipients: recipients,
        channelSpecificNotes: channelNotes,
      ));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get history detail: ${e.toString()}',
        code: 'HISTORY_DETAIL_ERR',
      ));
    }
  }

  @override
  Future<AppResult<RetryableActionHint?>> getRetryableActionHint(
      String entryId) async {
    try {
      final entryResult = await getHistoryEntryById(entryId);
      if (entryResult.isLeft()) return const Right(null);
      final entry = entryResult.getOrElse(() => null);
      if (entry == null) return const Right(null);

      if (entry.failedCount == 0) return const Right(null);

      String actionType;
      if (entry.channelType == 'sms') {
        actionType = 'retry_sms';
      } else {
        actionType = 'relaunch_whatsapp';
      }

      return Right(RetryableActionHint(
        entryId: entry.id,
        originalId: entry.originalId,
        channelType: entry.channelType,
        hasRetryableFailures: entry.failedCount > 0,
        failedCount: entry.failedCount,
        actionType: actionType,
      ));
    } on Exception catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get retry hint: ${e.toString()}',
        code: 'HISTORY_RETRY_HINT_ERR',
      ));
    }
  }

  Future<List<HistoryEntry>> _fetchSmsEntries({
    int? limit,
    int? offset,
  }) async {
    // direction: null = all (both inbound and outbound).
    final batchIds = await _localSource.listSmsBatchIds(
      limit: limit,
      offset: offset,
    );
    return _batchIdsToEntries(batchIds);
  }

  /// Builds a [HistoryDetailProjection] from raw batch rows.
  /// Extracted so it can be reused by both [getHistoryDetail] and
  /// [watchHistoryDetail] without duplicating logic.
  Future<HistoryDetailProjection> _buildSmsDetailProjection(
    String id,
    String batchId,
    List<db.MessageHistoryData> rows,
  ) async {
    String? groupName;
    final groupId = rows.first.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      groupName = await _localSource.getGroupName(groupId);
    }
    final entry = HistoryMapper.smsBatchToHistoryEntry(
      batchId: batchId,
      tenantId: _defaultTenantId,
      rows: rows,
      groupName: groupName,
    );

    const statusOrder = {
      'sent': 0, 'delivered': 0, 'failed': 1, 'queued': 2, 'sending': 2,
    };
    final resolver = _identityResolver ??
        (sl.isRegistered<ContactIdentityResolver>()
            ? sl<ContactIdentityResolver>()
            : null);
    final allRecipients = await Future.wait(rows.map((r) async {
      String name = r.contactName;
      if ((name.isEmpty || name == r.targetPhone) && resolver != null) {
        name = await resolver.resolveName(
          phoneOrSender: r.targetPhone,
          storedName: r.contactName,
        );
      }
      if (name.isEmpty) name = r.targetPhone;
      return RecipientDetail(
        name: name,
        phone: r.targetPhone,
        status: r.executionStatus,
        updatedAt: r.sentAt,
        messageId: r.id,
        peerId: r.peerId,
      );
    }));
    allRecipients.sort((a, b) =>
        (statusOrder[a.status] ?? 3).compareTo(statusOrder[b.status] ?? 3));

    final sentCount = rows
        .where((r) => MessageStatusService.isSuccess(r.executionStatus))
        .length;
    final failedCount = rows
        .where((r) => MessageStatusService.isFailed(r.executionStatus))
        .length;
    final queuedCount = rows
        .where((r) => MessageStatusService.isPending(r.executionStatus))
        .length;

    String? channelNotes;
    if (rows.length > 1) {
      channelNotes = 'SMS: $sentCount ✓ · $failedCount ✗ · $queuedCount ⏳';
    }

    return HistoryDetailProjection(
      entry: entry,
      recipients: allRecipients,
      channelSpecificNotes: channelNotes,
    );
  }

  Future<List<HistoryEntry>> _fetchWaEntries({
    int? limit,
    int? offset,
  }) async {
    final sessions = await _localSource.getWhatsAppSessions(
      limit: limit,
      offset: offset,
    );
    return sessions
        .map((s) => HistoryMapper.whatsAppSessionToHistoryEntry(
            row: s, tenantId: _defaultTenantId))
        .toList();
  }

  Future<List<HistoryEntry>> _fetchCombinedHistory({
    int? smsLimit,
    int? smsOffset,
    int? waLimit,
    int? waOffset,
  }) async {
    final smsEntries = await _fetchSmsEntries(
      limit: smsLimit,
      offset: smsOffset,
    );
    final waEntries = await _fetchWaEntries(
      limit: waLimit,
      offset: waOffset,
    );
    return _mergeAndSort(smsEntries, waEntries);
  }

  Future<List<HistoryEntry>> _batchIdsToEntries(
      List<String> batchIds) async {
    final entries = <HistoryEntry>[];
    // Cache group names within a single load call to avoid N×1 queries.
    final groupNameCache = <String, String?>{};

    for (final batchId in batchIds) {
      final rows = await _localSource.getSmsBatchRows(batchId);
      if (rows.isEmpty) continue;

      // Resolve group name if the batch is tagged with a groupId.
      String? groupName;
      final groupId = rows.first.groupId;
      if (groupId != null && groupId.isNotEmpty) {
        if (!groupNameCache.containsKey(groupId)) {
          groupNameCache[groupId] = await _localSource.getGroupName(groupId);
        }
        groupName = groupNameCache[groupId];
      }

      var entry = HistoryMapper.smsBatchToHistoryEntry(
        batchId: batchId,
        tenantId: _defaultTenantId,
        rows: rows,
        groupName: groupName,
      );

      final resolver = _identityResolver ??
          (sl.isRegistered<ContactIdentityResolver>()
              ? sl<ContactIdentityResolver>()
              : null);
      if (resolver != null &&
          (entry.contactName == null || entry.contactName!.isEmpty) &&
          entry.phoneNumber != null &&
          entry.phoneNumber!.isNotEmpty) {
        final resolvedName = await resolver.resolveName(
          phoneOrSender: entry.phoneNumber!,
          storedName: entry.contactName,
        );
        if (resolvedName != entry.phoneNumber) {
          entry = entry.copyWith(contactName: resolvedName);
        }
      }

      entries.add(entry);
    }
    return entries;
  }

  List<HistoryEntry> _mergeAndSort(
    List<HistoryEntry> smsEntries,
    List<HistoryEntry> waEntries,
  ) {
    final merged = [...smsEntries, ...waEntries];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  List<HistoryEntry> _applyPagination(
    List<HistoryEntry> entries, {
    int? limit,
    int? offset,
  }) {
    if (offset != null && offset > 0) {
      if (offset >= entries.length) return [];
      return entries.sublist(offset,
          limit != null ? offset + limit : null);
    }
    if (limit != null && limit < entries.length) {
      return entries.sublist(0, limit);
    }
    return entries;
  }

  String _epochToDateLabel(int epochSeconds) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';
  }
}
