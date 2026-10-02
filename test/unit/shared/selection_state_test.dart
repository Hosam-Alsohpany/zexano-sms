// ignore_for_file: lines_longer_than_80_chars
// Tests for SelectionState<T> + SelectionNotifier<T> (Invariant #11)

import 'package:flutter_test/flutter_test.dart';
import 'package:zexano_sms/shared/selection/selection_state.dart';

void main() {
  group('SelectionState<String>', () {
    test('initial state: not in selection mode, empty selection', () {
      final state = SelectionState<String>();
      expect(state.isSelectionMode, isFalse);
      expect(state.selectedIds, isEmpty);
      expect(state.hasSelection, isFalse);
      expect(state.selectedCount, equals(0));
    });

    test('isSelected: false for any id when empty', () {
      final state = SelectionState<String>();
      expect(state.isSelected('item-1'), isFalse);
    });

    test('isSelected: true for contained id', () {
      final state = SelectionState<String>(
        selectedIds: {'item-1', 'item-2'},
        isSelectionMode: true,
      );
      expect(state.isSelected('item-1'), isTrue);
      expect(state.isSelected('item-3'), isFalse);
    });

    test('selectedCount returns correct count', () {
      final state = SelectionState<String>(
        selectedIds: {'a', 'b', 'c'},
        isSelectionMode: true,
      );
      expect(state.selectedCount, equals(3));
    });

    test('copyWith preserves unchanged fields', () {
      final state = SelectionState<String>(
        selectedIds: {'item-1'},
        isSelectionMode: true,
      );
      final copy = state.copyWith(isSelectionMode: false);
      expect(copy.selectedIds, equals({'item-1'}));
      expect(copy.isSelectionMode, isFalse);
    });

    test('equality: same content → equal', () {
      final a = SelectionState<String>(
        selectedIds: {'x', 'y'},
        isSelectionMode: true,
      );
      final b = SelectionState<String>(
        selectedIds: {'x', 'y'},
        isSelectionMode: true,
      );
      expect(a, equals(b));
    });

    test('equality: different count → not equal', () {
      final a = SelectionState<String>(selectedIds: {'x'}, isSelectionMode: true);
      final b = SelectionState<String>(selectedIds: {'x', 'y'}, isSelectionMode: true);
      expect(a, isNot(equals(b)));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('SelectionNotifier<String>', () {
    late SelectionNotifier<String> notifier;

    setUp(() {
      notifier = SelectionNotifier<String>();
    });

    test('initial state is idle', () {
      expect(notifier.state.isSelectionMode, isFalse);
      expect(notifier.state.selectedIds, isEmpty);
    });

    // ── enterSelectionMode ─────────────────────────────────────────────────

    test('enterSelectionMode: enters selection mode and selects the item', () {
      notifier.enterSelectionMode('item-1');
      expect(notifier.state.isSelectionMode, isTrue);
      expect(notifier.state.selectedIds, contains('item-1'));
      expect(notifier.state.selectedCount, equals(1));
    });

    test('enterSelectionMode: replaces previous selection', () {
      notifier.enterSelectionMode('item-1');
      notifier.enterSelectionMode('item-2'); // long-press another item
      expect(notifier.state.selectedIds, equals({'item-2'}));
    });

    // ── toggle ─────────────────────────────────────────────────────────────

    test('toggle: adds unselected item', () {
      notifier.enterSelectionMode('item-1');
      notifier.toggle('item-2');
      expect(notifier.state.selectedIds, containsAll(['item-1', 'item-2']));
    });

    test('toggle: removes selected item', () {
      notifier.enterSelectionMode('item-1');
      notifier.toggle('item-1'); // deselect
      expect(notifier.state.selectedIds, isEmpty);
    });

    test('toggle: auto-exits selection mode when selection becomes empty', () {
      notifier.enterSelectionMode('item-1');
      notifier.toggle('item-1'); // removes last item
      expect(notifier.state.isSelectionMode, isFalse);
    });

    test('toggle: no-op when not in selection mode', () {
      notifier.toggle('item-1'); // not in selection mode
      expect(notifier.state.selectedIds, isEmpty);
      expect(notifier.state.isSelectionMode, isFalse);
    });

    // ── selectAll ──────────────────────────────────────────────────────────

    test('selectAll: selects all provided IDs', () {
      notifier.selectAll(['a', 'b', 'c', 'd', 'e']);
      expect(notifier.state.selectedIds, equals({'a', 'b', 'c', 'd', 'e'}));
      expect(notifier.state.isSelectionMode, isTrue);
    });

    test('selectAll: empty list → no-op (does not enter selection mode)', () {
      notifier.selectAll([]);
      expect(notifier.state.isSelectionMode, isFalse);
      expect(notifier.state.selectedIds, isEmpty);
    });

    test('selectAll: handles large paginated list', () {
      final ids = List.generate(100, (i) => 'item-$i');
      notifier.selectAll(ids);
      expect(notifier.state.selectedCount, equals(100));
    });

    // ── clear / cancel ─────────────────────────────────────────────────────

    test('clear: deselects all and exits selection mode', () {
      notifier.enterSelectionMode('item-1');
      notifier.toggle('item-2');
      notifier.clear();
      expect(notifier.state.isSelectionMode, isFalse);
      expect(notifier.state.selectedIds, isEmpty);
    });

    test('cancel: same as clear', () {
      notifier.enterSelectionMode('item-1');
      notifier.cancel();
      expect(notifier.state.isSelectionMode, isFalse);
      expect(notifier.state.hasSelection, isFalse);
    });

    // ── isSelected helper ──────────────────────────────────────────────────

    test('isSelected: returns true for selected, false for not selected', () {
      notifier.enterSelectionMode('item-1');
      expect(notifier.isSelected('item-1'), isTrue);
      expect(notifier.isSelected('item-2'), isFalse);
    });

    // ── Complex scenario: Long Press → Add → Remove → Add More → Clear ────

    test('full selection flow: long-press → add → remove → add → clear', () {
      // 1. Long press → enter selection mode
      notifier.enterSelectionMode('id-1');
      expect(notifier.state.selectedCount, equals(1));

      // 2. Tap to add more
      notifier.toggle('id-2');
      notifier.toggle('id-3');
      expect(notifier.state.selectedCount, equals(3));

      // 3. Tap to deselect one
      notifier.toggle('id-2');
      expect(notifier.state.selectedCount, equals(2));
      expect(notifier.state.isSelected('id-2'), isFalse);

      // 4. Select all
      notifier.selectAll(['id-1', 'id-2', 'id-3', 'id-4', 'id-5']);
      expect(notifier.state.selectedCount, equals(5));

      // 5. Clear
      notifier.clear();
      expect(notifier.state.isSelectionMode, isFalse);
      expect(notifier.state.hasSelection, isFalse);
    });

    // ── Generic type correctness ───────────────────────────────────────────

    test('SelectionNotifier<int> works for integer IDs', () {
      final intNotifier = SelectionNotifier<int>();
      intNotifier.enterSelectionMode(42);
      intNotifier.toggle(100);
      expect(intNotifier.state.selectedIds, containsAll([42, 100]));
      intNotifier.clear();
      expect(intNotifier.state.hasSelection, isFalse);
    });
  });
}
