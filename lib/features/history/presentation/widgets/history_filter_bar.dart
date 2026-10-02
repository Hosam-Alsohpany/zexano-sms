import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/history/domain/value_objects/history_filter_state.dart';
import 'package:zexano_sms/features/history/presentation/providers/history_providers.dart';

class HistoryFilterBar extends ConsumerWidget {
  final Function(String query) onSearch;
  final Function(String channel)? onChannelFilter;
  final Function(String direction)? onDirectionFilter;

  const HistoryFilterBar({
    super.key,
    required this.onSearch,
    this.onChannelFilter,
    this.onDirectionFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filterState = ref.watch(historyFilterProvider);
    final filterNotifier = ref.read(historyFilterProvider.notifier);

    final currentChannel = filterState.channelType;
    final currentDirection = filterState.direction;
    final currentStatus = filterState.status;
    final currentSourceType = filterState.sourceType;
    final currentDatePreset = filterState.datePreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchHistory,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            onChanged: (q) {
              filterNotifier.setSearchQuery(q);
              onSearch(q);
            },
          ),
        ),

        // ── Channel & Direction Row ─────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _FilterChip(
                label: l10n.allChannels,
                selected: currentChannel == 'all',
                onSelected: () {
                  filterNotifier.setChannel('all');
                  onChannelFilter?.call('all');
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: l10n.smsOnly,
                selected: currentChannel == 'sms',
                onSelected: () {
                  filterNotifier.setChannel('sms');
                  onChannelFilter?.call('sms');
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: l10n.whatsappOnly,
                selected: currentChannel == 'whatsapp',
                onSelected: () {
                  filterNotifier.setChannel('whatsapp');
                  onChannelFilter?.call('whatsapp');
                },
              ),

              // Direction chips (SMS)
              if (currentChannel == 'sms' || currentChannel == 'all') ...[
                const SizedBox(width: AppSpacing.md),
                Container(
                  height: 16,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: AppSpacing.md),
                _FilterChip(
                  label: l10n.filterAllMessages,
                  selected: currentDirection == 'all',
                  onSelected: () {
                    filterNotifier.setDirection('all');
                    onDirectionFilter?.call('all');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  icon: Icons.send_outlined,
                  label: l10n.filterSent,
                  selected: currentDirection == 'outbound',
                  onSelected: () {
                    filterNotifier.setDirection('outbound');
                    onDirectionFilter?.call('outbound');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  icon: Icons.call_received_outlined,
                  label: l10n.filterReceived,
                  selected: currentDirection == 'inbound',
                  onSelected: () {
                    filterNotifier.setDirection('inbound');
                    onDirectionFilter?.call('inbound');
                  },
                ),
              ],
            ],
          ),
        ),

        // ── Secondary Filters (Status, Type, Date) ─────────────────────────
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status Filter Chips
                _FilterChip(
                  label: l10n.filterDelivered,
                  selected: currentStatus == 'sent' || currentStatus == 'delivered',
                  onSelected: () {
                    filterNotifier.setStatus(
                        currentStatus == 'sent' || currentStatus == 'delivered'
                            ? null
                            : 'sent');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: l10n.filterFailed,
                  selected: currentStatus == 'failed',
                  onSelected: () {
                    filterNotifier.setStatus(
                        currentStatus == 'failed' ? null : 'failed');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: l10n.filterQueued,
                  selected: currentStatus == 'queued',
                  onSelected: () {
                    filterNotifier.setStatus(
                        currentStatus == 'queued' ? null : 'queued');
                  },
                ),

                const SizedBox(width: AppSpacing.md),
                Container(
                  height: 16,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: AppSpacing.md),

                // Source Type Filter Chips
                _FilterChip(
                  label: l10n.filterGroups,
                  selected: currentSourceType == 'group',
                  onSelected: () {
                    filterNotifier.setSourceType(
                        currentSourceType == 'group' ? null : 'group');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: l10n.filterBroadcasts,
                  selected: currentSourceType == 'broadcast',
                  onSelected: () {
                    filterNotifier.setSourceType(
                        currentSourceType == 'broadcast' ? null : 'broadcast');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: l10n.filterIndividual,
                  selected: currentSourceType == 'individual',
                  onSelected: () {
                    filterNotifier.setSourceType(
                        currentSourceType == 'individual' ? null : 'individual');
                  },
                ),

                const SizedBox(width: AppSpacing.md),
                Container(
                  height: 16,
                  width: 1,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: AppSpacing.md),

                // Date Preset Chips
                _FilterChip(
                  label: l10n.filterToday,
                  selected: currentDatePreset == DatePreset.today,
                  onSelected: () {
                    filterNotifier.setDatePreset(
                        currentDatePreset == DatePreset.today
                            ? DatePreset.all
                            : DatePreset.today);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: l10n.filterYesterday,
                  selected: currentDatePreset == DatePreset.yesterday,
                  onSelected: () {
                    filterNotifier.setDatePreset(
                        currentDatePreset == DatePreset.yesterday
                            ? DatePreset.all
                            : DatePreset.yesterday);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: l10n.filterLast7Days,
                  selected: currentDatePreset == DatePreset.last7Days,
                  onSelected: () {
                    filterNotifier.setDatePreset(
                        currentDatePreset == DatePreset.last7Days
                            ? DatePreset.all
                            : DatePreset.last7Days);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: l10n.filterLastMonth,
                  selected: currentDatePreset == DatePreset.lastMonth,
                  onSelected: () {
                    filterNotifier.setDatePreset(
                        currentDatePreset == DatePreset.lastMonth
                            ? DatePreset.all
                            : DatePreset.lastMonth);
                  },
                ),

                if (!filterState.isDefault) ...[
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    icon: const Icon(Icons.clear_all, size: 18),
                    tooltip: 'Reset Filters',
                    onPressed: () => filterNotifier.reset(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      avatar: icon != null
          ? Icon(icon,
              size: 14,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant)
          : null,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }
}
