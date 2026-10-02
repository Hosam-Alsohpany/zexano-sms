import 'package:flutter/material.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/history/domain/entities/history_entry.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

class HistoryEntryTile extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const HistoryEntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  // ── Icons ──────────────────────────────────────────────────────────────────

  IconData get _channelIcon {
    if (entry.channelType == 'whatsapp') return Icons.chat_bubble_outline;
    return entry.isInbound ? Icons.call_received_outlined : Icons.send_outlined;
  }

  Color _avatarBgColor(ThemeData theme) {
    if (entry.channelType == 'whatsapp') {
      return const Color(0xFF25D366).withOpacity(0.12);
    }
    if (entry.isInbound) {
      return theme.colorScheme.tertiaryContainer.withOpacity(0.6);
    }
    return theme.colorScheme.secondaryContainer;
  }

  Color _avatarIconColor(ThemeData theme) {
    if (entry.channelType == 'whatsapp') return const Color(0xFF25D366);
    if (entry.isInbound) return theme.colorScheme.onTertiaryContainer;
    return theme.colorScheme.onSecondaryContainer;
  }

  // ── Status ─────────────────────────────────────────────────────────────────

  /// Effective derived status using [MessageStatusService.deriveBatchStatus].
  String get _effectiveStatus {
    if (entry.isInbound) return 'received';
    final total = entry.totalRecipients;
    if (total == 0) return entry.status;

    final sent = entry.successCount;
    final failed = entry.failedCount;
    final queued = total - sent - failed;

    return MessageStatusService.deriveBatchStatus(
      sentCount: sent,
      failedCount: failed,
      queuedCount: queued > 0 ? queued : 0,
      total: total,
    );
  }

  Color _statusColor(ThemeData theme) {
    final status = _effectiveStatus;
    if (MessageStatusService.isSuccess(status)) {
      return theme.colorScheme.primary;
    } else if (MessageStatusService.isFailed(status)) {
      return theme.colorScheme.error;
    } else if (status == 'partial') {
      return theme.colorScheme.tertiary;
    } else if (status == 'queued') {
      return Colors.orange.shade400;
    } else if (status == 'sending') {
      return Colors.blue.shade400;
    } else if (status == 'received') {
      return theme.colorScheme.primary;
    } else if (status == 'in_progress') {
      return Colors.orange.shade400;
    } else if (status == 'cancelled') {
      return theme.colorScheme.onSurfaceVariant;
    }
    return theme.colorScheme.onSurfaceVariant;
  }

  String _statusLabel(AppLocalizations l10n) {
    final status = _effectiveStatus;
    switch (status) {
      case 'sent':
        return l10n.statusSentLabel;
      case 'delivered':
        return l10n.statusDeliveredLabel;
      case 'failed':
        return l10n.statusFailedLabel;
      case 'partial':
        return l10n.statusPartialLabel;
      case 'queued':
        return l10n.statusQueuedLabel;
      case 'sending':
        return l10n.statusSendingLabel;
      case 'received':
        return l10n.statusReceivedLabel;
      case 'completed':
        return l10n.statusDeliveredLabel;
      case 'in_progress':
        return l10n.statusSendingLabel;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return l10n.statusUnknownLabel;
    }
  }

  // ── Source badge ───────────────────────────────────────────────────────────

  Widget? _sourceBadge(ThemeData theme, AppLocalizations l10n) {
    final label = switch (entry.sourceType) {
      'group' => l10n.filterGroups,
      'contact' => l10n.filterIndividual,
      'import' => l10n.filterBroadcasts,
      'inbound' => null,
      'manual' => null,
      'whatsapp' => null,
      _ => null,
    };
    if (label == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }

  // ── Timestamp ──────────────────────────────────────────────────────────────

  String _formatTimestamp(int epochSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor(theme);
    final sourceBadge = _sourceBadge(theme, l10n);
    final timestamp = entry.isInbound && entry.receivedAt != null
        ? _formatTimestamp(entry.receivedAt!)
        : _formatTimestamp(entry.createdAt);

    final displayName = entry.buildDisplayTitle(
      broadcastFormatter: (n) => l10n.broadcastNRecipients(n),
      fallback: l10n.unknown,
    );

    return Card(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              CircleAvatar(
                backgroundColor: isSelected
                    ? theme.colorScheme.primary
                    : _avatarBgColor(theme),
                child: Icon(
                  isSelected ? Icons.check : _channelIcon,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : _avatarIconColor(theme),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + optional source badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (sourceBadge != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          sourceBadge,
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Message preview
                    Text(
                      entry.messageBody,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (entry.totalRecipients > 1) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${entry.successCount}/${entry.totalRecipients}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (entry.failedCount > 0) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.error_outline,
                              size: 13,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${entry.failedCount}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // ── Trailing: status + time ────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Text(
                      _statusLabel(l10n),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    timestamp,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
