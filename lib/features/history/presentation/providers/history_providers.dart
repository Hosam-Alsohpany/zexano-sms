import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/history/domain/repositories/history_repository.dart';
import 'package:zexano_sms/features/history/domain/value_objects/history_filter_state.dart';

// \u2500\u2500 Repository \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return sl<HistoryRepository>();
});

// \u2500\u2500 Single filter state (replaces the old scatter of individual providers) \u2500\u2500\u2500\u2500\u2500\u2500

/// The single source of truth for all History screen filters.
///
/// Replaces the former [historyChannelFilterProvider],
/// [historyDirectionFilterProvider], and [historySearchQueryProvider].
/// All filter dimensions are now colocated in [HistoryFilterState].
class HistoryFilterNotifier extends StateNotifier<HistoryFilterState> {
  HistoryFilterNotifier() : super(const HistoryFilterState());

  void setChannel(String channel) =>
      state = state.copyWith(channelType: channel);

  void setDirection(String direction) =>
      state = state.copyWith(direction: direction);

  void setStatus(String? status) =>
      state = state.copyWith(status: status, clearStatus: status == null);

  void setSourceType(String? sourceType) => state =
      state.copyWith(sourceType: sourceType, clearSourceType: sourceType == null);

  void setSearchQuery(String query) => state = state.copyWith(
        searchQuery: query.isEmpty ? null : query,
        clearSearchQuery: query.isEmpty,
      );

  void setDatePreset(DatePreset preset) =>
      state = state.copyWith(datePreset: preset);

  void setCustomDateRange(DateTime from, DateTime to) => state = state.copyWith(
        datePreset: DatePreset.custom,
        customFrom: from,
        customTo: to,
      );

  void reset() => state = const HistoryFilterState();
}

final historyFilterProvider =
    StateNotifierProvider<HistoryFilterNotifier, HistoryFilterState>(
  (ref) => HistoryFilterNotifier(),
);

// \u2500\u2500 Convenience computed providers (derived from historyFilterProvider) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

/// Backwards-compat alias \u2014 consumed by [HistoryFilterBar] and [HistoryNotifier].
/// Prefer [historyFilterProvider] for new code.
final historyChannelFilterProvider = Provider<String>((ref) {
  return ref.watch(historyFilterProvider).channelType;
});

final historyDirectionFilterProvider = Provider<String>((ref) {
  return ref.watch(historyFilterProvider).direction;
});

final historySearchQueryProvider = Provider<String>((ref) {
  return ref.watch(historyFilterProvider).searchQuery ?? '';
});
