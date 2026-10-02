/// Immutable composite filter state for the History screen.
///
/// A single [HistoryFilterState] object replaces the previous scatter of
/// individual StateProviders (channel, direction, status, ...). All filter
/// dimensions are colocated \u2014 callers use [copyWith] to produce updated
/// snapshots without mutating the original.
library history_filter_state;

// \u2500\u2500 DatePreset \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

enum DatePreset {
  all,
  today,
  yesterday,
  last7Days,
  lastMonth,
  custom,
}

// \u2500\u2500 HistoryFilterState \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500

class HistoryFilterState {
  /// 'all' | 'sms' | 'whatsapp'
  final String channelType;

  /// 'all' | 'outbound' | 'inbound'
  final String direction;

  /// null = no status filter.
  /// Values: 'sent' | 'delivered' | 'failed' | 'partial' | 'queued'
  final String? status;

  /// null = all source types.
  /// Values: 'manual' | 'group' | 'contact' | 'import' | 'inbound'
  final String? sourceType;

  /// Free-text search query. null or empty = no search.
  final String? searchQuery;

  /// Quick date filter preset.
  final DatePreset datePreset;

  /// Custom date range start (used only when [datePreset] == [DatePreset.custom]).
  final DateTime? customFrom;

  /// Custom date range end (used only when [datePreset] == [DatePreset.custom]).
  final DateTime? customTo;

  const HistoryFilterState({
    this.channelType = 'all',
    this.direction = 'all',
    this.status,
    this.sourceType,
    this.searchQuery,
    this.datePreset = DatePreset.all,
    this.customFrom,
    this.customTo,
  });

  /// Returns `true` when no filter is active (default state).
  bool get isDefault =>
      channelType == 'all' &&
      direction == 'all' &&
      status == null &&
      sourceType == null &&
      (searchQuery == null || searchQuery!.isEmpty) &&
      datePreset == DatePreset.all;

  /// Computes the [dateFrom] epoch-seconds for the current preset.
  /// Returns null when [datePreset] == [DatePreset.all].
  int? get computedDateFrom {
    final now = DateTime.now();
    return switch (datePreset) {
      DatePreset.all    => null,
      DatePreset.today  => DateTime(now.year, now.month, now.day)
          .millisecondsSinceEpoch ~/ 1000,
      DatePreset.yesterday => DateTime(now.year, now.month, now.day - 1)
          .millisecondsSinceEpoch ~/ 1000,
      DatePreset.last7Days => now
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch ~/ 1000,
      DatePreset.lastMonth => now
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch ~/ 1000,
      DatePreset.custom => customFrom?.millisecondsSinceEpoch != null
          ? customFrom!.millisecondsSinceEpoch ~/ 1000
          : null,
    };
  }

  /// Computes the [dateTo] epoch-seconds for the current preset.
  int? get computedDateTo {
    if (datePreset == DatePreset.custom) {
      return customTo?.millisecondsSinceEpoch != null
          ? customTo!.millisecondsSinceEpoch ~/ 1000
          : null;
    }
    // For presets other than "all" and "custom", dateTo = now.
    if (datePreset == DatePreset.all) return null;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  HistoryFilterState copyWith({
    String? channelType,
    String? direction,
    String? status,
    String? sourceType,
    String? searchQuery,
    DatePreset? datePreset,
    DateTime? customFrom,
    DateTime? customTo,
    bool clearStatus = false,
    bool clearSourceType = false,
    bool clearSearchQuery = false,
    bool clearCustomRange = false,
  }) {
    return HistoryFilterState(
      channelType: channelType ?? this.channelType,
      direction: direction ?? this.direction,
      status: clearStatus ? null : (status ?? this.status),
      sourceType: clearSourceType ? null : (sourceType ?? this.sourceType),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      datePreset: datePreset ?? this.datePreset,
      customFrom: clearCustomRange ? null : (customFrom ?? this.customFrom),
      customTo: clearCustomRange ? null : (customTo ?? this.customTo),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryFilterState &&
        other.channelType == channelType &&
        other.direction == direction &&
        other.status == status &&
        other.sourceType == sourceType &&
        other.searchQuery == searchQuery &&
        other.datePreset == datePreset &&
        other.customFrom == customFrom &&
        other.customTo == customTo;
  }

  @override
  int get hashCode => Object.hash(
        channelType,
        direction,
        status,
        sourceType,
        searchQuery,
        datePreset,
        customFrom,
        customTo,
      );

  @override
  String toString() =>
      'HistoryFilterState(ch: $channelType, dir: $direction, '
      'status: $status, source: $sourceType, date: $datePreset)';
}
