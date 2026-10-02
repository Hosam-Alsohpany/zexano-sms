import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';
import 'package:zexano_sms/features/history/domain/models/grouped_timeline_result.dart';
import 'package:zexano_sms/features/history/presentation/providers/history_providers.dart';
import 'package:zexano_sms/features/history/presentation/widgets/history_entry_tile.dart';

class HistoryTimelineScreen extends ConsumerWidget {
  const HistoryTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.watch(historyRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.timeline),
      ),
      body: FutureBuilder(
        future: repo.buildGroupedTimeline(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorOccurred));
          }
          final result = snapshot.data;
          if (result == null || result.isLeft()) {
            return Center(child: Text(l10n.noData));
          }
          final groups = result.getOrElse(() => <GroupedTimelineResult>[]);
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline_outlined,
                    size: 80,
                    color:
                        theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
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
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(
                top: AppSpacing.sm, bottom: AppSpacing.xxl),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _TimelineGroup(
                group: group,
                onEntryTap: (entry) =>
                    context.push('/history/${entry.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _TimelineGroup extends StatelessWidget {
  final GroupedTimelineResult group;
  final void Function(HistoryEntry entry) onEntryTap;

  const _TimelineGroup({
    required this.group,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Text(
                group.dateLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${group.totalCount}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...group.entries.map(
          (entry) => HistoryEntryTile(
            entry: entry,
            onTap: () => onEntryTap(entry),
          ),
        ),
      ],
    );
  }
}
