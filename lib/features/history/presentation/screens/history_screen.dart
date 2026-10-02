import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';
import 'package:zexano_sms/features/history/presentation/controllers/history_notifier.dart';
import 'package:zexano_sms/features/history/presentation/providers/history_providers.dart';
import 'package:zexano_sms/features/history/presentation/widgets/history_entry_tile.dart';
import 'package:zexano_sms/features/history/presentation/widgets/history_filter_bar.dart';
import 'package:zexano_sms/shared/selection/selection_state.dart';

final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<HistoryEntry>>>(
  (ref) => HistoryNotifier(ref),
);

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with RouteAware {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(historyNotifierProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(historyNotifierProvider);
    final selectionState = ref.watch(historySelectionProvider);
    final selectionNotifier = ref.read(historySelectionProvider.notifier);

    return Scaffold(
      appBar: selectionState.isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => selectionNotifier.clear(),
              ),
              title: Text(l10n.selectedCount(selectionState.selectedCount)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: l10n.selectAll,
                  onPressed: () {
                    final currentEntries = historyAsync.valueOrNull ?? [];
                    selectionNotifier.selectAll(currentEntries.map((e) => e.id));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.deleteSelected,
                  onPressed: () =>
                      _deleteSelectedHistory(context, selectionState),
                ),
              ],
            )
          : AppBar(
              title: Text(l10n.history),
              actions: [
                IconButton(
                  icon: const Icon(Icons.timeline_outlined),
                  tooltip: l10n.timeline,
                  onPressed: () => context.push('/history/timeline'),
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart_outlined),
                  tooltip: l10n.historyStats,
                  onPressed: () => context.push('/history/stats'),
                ),
              ],
            ),
      body: PopScope(
        canPop: !selectionState.isSelectionMode,
        onPopInvoked: (didPop) {
          if (!didPop && selectionState.isSelectionMode) {
            selectionNotifier.clear();
          }
        },
        child: Column(
          children: [
            HistoryFilterBar(
              onSearch: (query) => ref
                  .read(historyNotifierProvider.notifier)
                  .setSearchQuery(query),
              onChannelFilter: (channel) => ref
                  .read(historyNotifierProvider.notifier)
                  .setChannelFilter(channel),
              onDirectionFilter: (direction) => ref
                  .read(historyNotifierProvider.notifier)
                  .setDirectionFilter(direction),
            ),
            Expanded(
              child: historyAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildError(context, error),
                data: (entries) => entries.isEmpty
                    ? _buildEmpty(context)
                    : _buildList(context, entries, selectionState,
                        selectionNotifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelectedHistory(
      BuildContext context, SelectionState<String> selectionState) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSelected),
        content: Text(l10n.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final selectedList = selectionState.selectedIds.toList();
      final repo = ref.read(historyRepositoryProvider);
      final result = await repo.deleteHistoryEntries(selectedList);
      if (!mounted) return;
      ref.read(historySelectionProvider.notifier).clear();
      ref.read(historyNotifierProvider.notifier).refresh();
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        ),
        (count) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count ${l10n.entryDeleted}')),
        ),
      );
    }
  }

  Widget _buildError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.errorOccurred, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(historyNotifierProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.noHistory,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context,
      List<HistoryEntry> entries,
      SelectionState<String> selectionState,
      SelectionNotifier<String> selectionNotifier) {
    return RefreshIndicator(
      onRefresh: () => ref.read(historyNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xxl,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isSelected = selectionState.isSelected(entry.id);
          return HistoryEntryTile(
            entry: entry,
            isSelected: isSelected,
            isSelectionMode: selectionState.isSelectionMode,
            onTap: () async {
              if (selectionState.isSelectionMode) {
                selectionNotifier.toggle(entry.id);
              } else {
                await context.push('/history/${entry.id}');
                if (context.mounted) {
                  ref.read(historyNotifierProvider.notifier).refresh();
                }
              }
            },
            onLongPress: () {
              if (!selectionState.isSelectionMode) {
                selectionNotifier.enterSelectionMode(entry.id);
              } else {
                selectionNotifier.toggle(entry.id);
              }
            },
          );
        },
      ),
    );
  }
}
