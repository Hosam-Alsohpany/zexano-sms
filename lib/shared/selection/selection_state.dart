import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── State ────────────────────────────────────────────────────────────────────

/// Invariant #11: Unified selection state shared across all screens.
///
/// Generic over [T] — the type of the item identifier (usually `String` id).
/// Used by:
///   - Contacts screen
///   - Group Members screen (family: groupId)
///   - History screen
///   - Conversations screen
///   - Message/History Detail screen (family: batchId)
class SelectionState<T> {
  /// IDs of currently selected items.
  final Set<T> selectedIds;

  /// Whether the UI is in selection mode (long-press activated).
  final bool isSelectionMode;

  SelectionState({
    Set<T>? selectedIds,
    this.isSelectionMode = false,
  }) : selectedIds = selectedIds ?? <T>{};

  /// True when at least one item is selected.
  bool get hasSelection => selectedIds.isNotEmpty;

  /// Number of currently selected items.
  int get selectedCount => selectedIds.length;

  /// True if [id] is currently selected.
  bool isSelected(T id) => selectedIds.contains(id);

  SelectionState<T> copyWith({
    Set<T>? selectedIds,
    bool? isSelectionMode,
  }) {
    return SelectionState<T>(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionState<T> &&
          other.isSelectionMode == isSelectionMode &&
          _setsEqual(other.selectedIds, selectedIds);

  @override
  int get hashCode => Object.hash(isSelectionMode, selectedIds.length);

  static bool _setsEqual<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  String toString() =>
      'SelectionState(mode=$isSelectionMode, selected=${selectedIds.length})';
}

// ── Notifier ─────────────────────────────────────────────────────────────────

/// Manages [SelectionState] for a list of items of type [T].
///
/// All 5 screens use this notifier — no divergent per-screen implementations.
///
/// **UX Rules (from user spec):**
///   - Long Press on item → enter selection mode, select that item
///   - Tap on item (in selection mode) → toggle selection
///   - [selectAll] → selects all provided IDs (handles paginated lists: select all loaded)
///   - [clear] → deselects all, exits selection mode
///   - [cancel] → alias for [clear]
class SelectionNotifier<T> extends StateNotifier<SelectionState<T>> {
  SelectionNotifier() : super(SelectionState<T>());

  /// Enters selection mode and selects [id].
  /// Called on Long Press.
  void enterSelectionMode(T id) {
    state = SelectionState<T>(
      selectedIds: {id},
      isSelectionMode: true,
    );
  }

  /// Toggles [id] selection.
  /// In selection mode, tap on item calls this.
  /// Exits selection mode automatically if selection becomes empty.
  void toggle(T id) {
    if (!state.isSelectionMode) return;

    final updated = Set<T>.from(state.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }

    state = SelectionState<T>(
      selectedIds: updated,
      isSelectionMode: updated.isNotEmpty, // auto-exit if nothing selected
    );
  }

  /// Selects all [ids].
  ///
  /// For paginated lists, [ids] should be all currently loaded items.
  /// This covers the "Select all loaded" requirement.
  void selectAll(Iterable<T> ids) {
    final all = Set<T>.from(ids);
    state = SelectionState<T>(
      selectedIds: all,
      isSelectionMode: all.isNotEmpty,
    );
  }

  /// Deselects all items and exits selection mode.
  void clear() {
    state = SelectionState<T>();
  }

  /// Alias for [clear]. Called when user taps Cancel.
  void cancel() => clear();

  /// Returns true if [id] is currently selected.
  bool isSelected(T id) => state.isSelected(id);
}

// ── Per-screen Providers ─────────────────────────────────────────────────────
//
// All providers use autoDispose so state is cleaned up when the screen pops.
// Family variants use a key (groupId, batchId) to scope state per-instance.

/// Selection state for the Contacts screen.
final contactSelectionProvider = StateNotifierProvider.autoDispose<
    SelectionNotifier<String>, SelectionState<String>>(
  (ref) => SelectionNotifier<String>(),
);

/// Selection state for a Group Members screen (scoped by groupId).
final groupMemberSelectionProvider = StateNotifierProvider.autoDispose
    .family<SelectionNotifier<String>, SelectionState<String>, String>(
  (ref, groupId) => SelectionNotifier<String>(),
);

/// Selection state for the History screen (batch-level selection).
final historySelectionProvider = StateNotifierProvider.autoDispose<
    SelectionNotifier<String>, SelectionState<String>>(
  (ref) => SelectionNotifier<String>(),
);

/// Selection state for the Conversations screen.
final conversationSelectionProvider = StateNotifierProvider.autoDispose<
    SelectionNotifier<String>, SelectionState<String>>(
  (ref) => SelectionNotifier<String>(),
);

/// Selection state for messages within a History Detail or Conversation.
/// Scoped by [batchId] / [peerId] to prevent cross-screen state bleed.
final messageSelectionProvider = StateNotifierProvider.autoDispose
    .family<SelectionNotifier<String>, SelectionState<String>, String>(
  (ref, scopeId) => SelectionNotifier<String>(),
);
