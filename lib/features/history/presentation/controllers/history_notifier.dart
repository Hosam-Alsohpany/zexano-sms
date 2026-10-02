import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';
import 'package:zexano_sms/features/history/domain/value_objects/history_filter_state.dart';
import 'package:zexano_sms/features/history/presentation/providers/history_providers.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

class HistoryNotifier extends StateNotifier<AsyncValue<List<HistoryEntry>>> {
  final Ref _ref;
  StreamSubscription<List<HistoryEntry>>? _subscription;
  List<HistoryEntry> _rawEntries = [];

  HistoryNotifier(this._ref) : super(const AsyncValue.loading()) {
    _startWatching();
    _listenToFilters();
  }

  void _listenToFilters() {
    _ref.listen<HistoryFilterState>(historyFilterProvider, (previous, next) {
      if (_rawEntries.isNotEmpty) {
        state = AsyncValue.data(_applyFilters(_rawEntries, next));
      } else {
        _doLoad();
      }
    });
  }

  /// Subscribes directly to [HistoryRepository.watchMessageHistory].
  ///
  /// The stream does all the heavy lifting (resolves group names,
  /// computes per-batch status from live DB rows, merges WhatsApp sessions).
  /// Any DB write or status update instantly updates _rawEntries and re-filters.
  void _startWatching() {
    _subscription?.cancel();
    final repo = _ref.read(historyRepositoryProvider);

    _subscription = repo.watchMessageHistory().listen(
      (entries) {
        _rawEntries = entries;
        final filterState = _ref.read(historyFilterProvider);
        final filtered = _applyFilters(entries, filterState);
        state = AsyncValue.data(filtered);
      },
      onError: (e, st) {
        if (!state.hasValue) {
          state = AsyncValue.error(e, st);
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  Future<void> refresh() async {
    await _doLoad();
  }

  void setChannelFilter(String channel) {
    _ref.read(historyFilterProvider.notifier).setChannel(channel);
  }

  void setSearchQuery(String query) {
    _ref.read(historyFilterProvider.notifier).setSearchQuery(query);
  }

  void setDirectionFilter(String direction) {
    _ref.read(historyFilterProvider.notifier).setDirection(direction);
  }

  void setStatusFilter(String? status) {
    _ref.read(historyFilterProvider.notifier).setStatus(status);
  }

  void setSourceTypeFilter(String? sourceType) {
    _ref.read(historyFilterProvider.notifier).setSourceType(sourceType);
  }

  void setDatePreset(DatePreset preset) {
    _ref.read(historyFilterProvider.notifier).setDatePreset(preset);
  }

  void resetFilters() {
    _ref.read(historyFilterProvider.notifier).reset();
  }

  Future<void> deleteEntry(String id) async {
    final previousState = state;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(historyRepositoryProvider);
      await repo.deleteHistoryEntry(id);
      final result = await repo.listMessageHistory();
      _rawEntries = result.fold((f) => throw f, (list) => list);
      final filterState = _ref.read(historyFilterProvider);
      return _applyFilters(_rawEntries, filterState);
    });
    if (state.hasError) {
      state = previousState;
    }
  }

  Future<void> clearHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(historyRepositoryProvider);
      await repo.clearHistory();
      final result = await repo.listMessageHistory();
      _rawEntries = result.fold((f) => throw f, (list) => list);
      final filterState = _ref.read(historyFilterProvider);
      return _applyFilters(_rawEntries, filterState);
    });
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _doLoad() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(historyRepositoryProvider);
      final filterState = _ref.read(historyFilterProvider);

      final result = await repo.listMessageHistory();
      _rawEntries = result.fold((f) => throw f, (list) => list);

      return _applyFilters(_rawEntries, filterState);
    });
  }

  List<HistoryEntry> _applyFilters(
    List<HistoryEntry> entries,
    HistoryFilterState filter,
  ) {
    return entries.where((e) {
      // 1. Channel filter
      if (filter.channelType != 'all' && e.channelType != filter.channelType) {
        return false;
      }

      // 2. Direction filter
      if (filter.direction != 'all' && e.direction != filter.direction) {
        return false;
      }

      // 3. Status filter
      if (filter.status != null) {
        final targetStatus = filter.status!;
        if (targetStatus == 'sent' || targetStatus == 'delivered') {
          if (!MessageStatusService.isSuccess(e.status)) return false;
        } else if (targetStatus == 'failed') {
          if (!MessageStatusService.isFailed(e.status)) return false;
        } else if (targetStatus == 'queued' || targetStatus == 'sending') {
          if (!MessageStatusService.isPending(e.status)) return false;
        } else if (targetStatus == 'partial') {
          if (e.status != 'partial') return false;
        } else if (e.status != targetStatus) {
          return false;
        }
      }

      // 4. Source type filter
      if (filter.sourceType != null) {
        final st = filter.sourceType!;
        if (st == 'group') {
          if (e.sourceType != 'group' && !e.isGroupSend) return false;
        } else if (st == 'broadcast') {
          if (e.totalRecipients <= 1 || e.isGroupSend) return false;
        } else if (st == 'individual') {
          if (e.totalRecipients != 1) return false;
        } else if (e.sourceType != st) {
          return false;
        }
      }

      // 5. Search query
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final q = filter.searchQuery!.trim().toLowerCase();
        final bodyMatch = e.messageBody.toLowerCase().contains(q);
        final contactMatch = e.contactName?.toLowerCase().contains(q) ?? false;
        final phoneMatch = e.phoneNumber?.toLowerCase().contains(q) ?? false;
        final groupMatch = e.groupName?.toLowerCase().contains(q) ?? false;
        if (!bodyMatch && !contactMatch && !phoneMatch && !groupMatch) {
          return false;
        }
      }

      // 6. Date Range filter
      final from = filter.computedDateFrom;
      final to = filter.computedDateTo;
      if (from != null || to != null) {
        final timestamp = e.isInbound && e.receivedAt != null
            ? e.receivedAt!
            : e.createdAt;
        if (from != null && timestamp < from) return false;
        if (to != null && timestamp > to) return false;
      }

      return true;
    }).toList();
  }
}
