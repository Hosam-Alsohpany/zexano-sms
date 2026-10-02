import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/history/domain/models/history_detail_projection.dart';
import 'package:zexano_sms/features/history/domain/models/recipient_detail.dart';
import 'package:zexano_sms/features/history/domain/models/retryable_action_hint.dart';
import 'package:zexano_sms/features/history/presentation/providers/history_providers.dart';
import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';
import 'package:zexano_sms/features/sms/domain/services/sms_capability_service.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class HistoryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const HistoryDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<HistoryDetailScreen> createState() =>
      _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
  /// Live stream for detail projection — updates automatically when DB rows change.
  late final Stream<AppResult<HistoryDetailProjection>> _detailStream;
  late final Future<AppResult<RetryableActionHint?>> _retryHintFuture;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(historyRepositoryProvider);
    _detailStream = repo.watchHistoryDetail(widget.entryId);
    _retryHintFuture = repo.getRetryableActionHint(widget.entryId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(historyRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteEntry,
            onPressed: () => _confirmDelete(context, l10n, repo),
          ),
        ],
      ),
      body: StreamBuilder<AppResult<HistoryDetailProjection>>(
        stream: _detailStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorView(context, theme, l10n);
          }
          final result = snapshot.data;
          if (result == null || result.isLeft()) {
            return Center(child: Text(l10n.noData));
          }
          final detail =
              result.getOrElse(() => throw StateError('unexpected'));
          return _buildBody(context, theme, l10n, detail);
        },
      ),
    );
  }

  // ── Delete flow ─────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    dynamic repo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteEntry),
        content: Text(l10n.deleteEntryConfirmation),
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
    if (confirmed == true && context.mounted) {
      await repo.deleteHistoryEntry(widget.entryId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.entryDeleted)),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // ── Error view ─────────────────────────────────────────────────────────────

  Widget _errorView(
      BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: theme.colorScheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.errorOccurred,
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => setState(() {
              final repo = ref.read(historyRepositoryProvider);
              _detailStream = repo.watchHistoryDetail(widget.entryId);
            }),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    HistoryDetailProjection detail,
  ) {
    final entry = detail.entry;
    // Use derivedStatus (computed from live recipients) not entry.status.
    final displayStatus = detail.derivedStatus;
    final statusColor = _statusColor(displayStatus, theme);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Message / batch header card ─────────────────────────────────
          _MessageCard(
            detail: detail,
            displayStatus: displayStatus,
            statusColor: statusColor,
            theme: theme,
            l10n: l10n,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Stats tiles ────────────────────────────────────────────────
          _StatsSummaryCard(detail: detail, theme: theme, l10n: l10n),
          const SizedBox(height: AppSpacing.md),

          // ── Per-recipient breakdown (SMS only) ─────────────────────────
          if (detail.hasRecipients) ...[
            _RecipientsSection(detail: detail, theme: theme, l10n: l10n),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Retry hint banner (failures only) ─────────────────────────
          if (entry.failedCount > 0)
            FutureBuilder<AppResult<RetryableActionHint?>>(
              future: _retryHintFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                final hint = snapshot.data?.getOrElse(() => null);
                if (hint == null || !hint.hasRetryableFailures) {
                  return const SizedBox.shrink();
                }
                return _RetryBanner(
                  batchId: entry.originalId,
                  failedCount: entry.failedCount,
                  channelType: entry.channelType,
                  theme: theme,
                  l10n: l10n,
                );
              },
            ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Color _statusColor(String status, ThemeData theme) {
    if (MessageStatusService.isSuccess(status)) {
      return theme.colorScheme.primary;
    } else if (MessageStatusService.isFailed(status)) {
      return theme.colorScheme.error;
    } else if (status == 'partial') {
      return theme.colorScheme.tertiary;
    } else if (status == 'queued') {
      return Colors.orange;
    } else if (status == 'sending' || status == 'in_progress') {
      return Colors.blue;
    } else if (status == 'cancelled') {
      return theme.colorScheme.onSurfaceVariant;
    }
    return theme.colorScheme.onSurfaceVariant;
  }
}

// ── Message card ─────────────────────────────────────────────────────────────

class _MessageCard extends StatelessWidget {
  final HistoryDetailProjection detail;
  final String displayStatus;
  final Color statusColor;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _MessageCard({
    required this.detail,
    required this.displayStatus,
    required this.statusColor,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final entry = detail.entry;
    final displayName = entry.buildDisplayTitle(
      broadcastFormatter: (n) => l10n.broadcastNRecipients(n),
      fallback: l10n.unknown,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Channel + status row
            Row(
              children: [
                Icon(
                  entry.channelType == 'whatsapp'
                      ? Icons.chat_bubble_outline
                      : Icons.sms,
                  color: entry.channelType == 'whatsapp'
                      ? const Color(0xFF25D366)
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.channelType == 'whatsapp'
                        ? l10n.whatsapp
                        : l10n.messaging,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                _StatusChip(
                  status: displayStatus,
                  color: statusColor,
                  l10n: l10n,
                ),
              ],
            ),

            // Batch title (group name / broadcast / contact name)
            if (displayName.isNotEmpty && displayName != l10n.unknown) ...[
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                onTap: !detail.isBulk
                    ? () {
                        final phone = detail.hasRecipients
                            ? detail.recipients.first.phone
                            : (entry.phoneNumber ?? '');
                        if (phone.isEmpty) return;
                        final peerId = (detail.hasRecipients
                                ? detail.recipients.first.peerId
                                : null) ??
                            sl<NormalizationEngine>().peerIdFor(phone);
                        final targetMessageId = detail.hasRecipients
                            ? detail.recipients.first.messageId
                            : entry.originalId;
                        context.push(
                          '/messaging/conversation',
                          extra: {
                            'peerId': peerId,
                            'displayName': displayName,
                            'targetMessageId': targetMessageId,
                          },
                        );
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        entry.isGroupSend
                            ? Icons.group_outlined
                            : (detail.isBulk
                                ? Icons.people_outline
                                : Icons.person_outline),
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!detail.isBulk)
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color:
                              theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const Divider(height: AppSpacing.xl),

            // Message body
            Text(
              l10n.messageBody,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              entry.messageBody,
              style: theme.textTheme.bodyLarge,
            ),

            // Timestamp
            if (entry.completedAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatTimestamp(entry.completedAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(int epochSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
        '-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  final AppLocalizations l10n;

  const _StatusChip({
    required this.status,
    required this.color,
    required this.l10n,
  });

  String _statusLabel() {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _statusLabel(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Stats summary card ────────────────────────────────────────────────────────

class _StatsSummaryCard extends StatelessWidget {
  final HistoryDetailProjection detail;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _StatsSummaryCard({
    required this.detail,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final total = detail.totalCount;
    final sent = detail.sentCount;
    final failed = detail.failedCount;
    final queued = detail.queuedCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.status, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.people_outline,
                    label: l10n.recipientCount,
                    value: '$total',
                    color: theme.colorScheme.onSurfaceVariant,
                    theme: theme,
                  ),
                ),
                if (sent > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.check_circle_outline,
                      label: l10n.successCount,
                      value: '$sent',
                      color: theme.colorScheme.primary,
                      theme: theme,
                    ),
                  ),
                ],
                if (failed > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.cancel_outlined,
                      label: l10n.failCount,
                      value: '$failed',
                      color: theme.colorScheme.error,
                      theme: theme,
                    ),
                  ),
                ],
                if (queued > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.hourglass_empty_outlined,
                      label: l10n.filterQueued,
                      value: '$queued',
                      color: Colors.orange,
                      theme: theme,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Recipients section ────────────────────────────────────────────────────────

class _RecipientsSection extends StatelessWidget {
  final HistoryDetailProjection detail;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _RecipientsSection({
    required this.detail,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.sentRecipients.isNotEmpty) ...[
          _RecipientGroup(
            title: '✅ ${l10n.successCount} (${detail.sentRecipients.length})',
            recipients: detail.sentRecipients,
            color: theme.colorScheme.primary,
            theme: theme,
            l10n: l10n,
            startExpanded: true,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (detail.failedRecipients.isNotEmpty) ...[
          _RecipientGroup(
            title: '❌ ${l10n.failCount} (${detail.failedRecipients.length})',
            recipients: detail.failedRecipients,
            color: theme.colorScheme.error,
            theme: theme,
            l10n: l10n,
            startExpanded: true,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (detail.queuedRecipients.isNotEmpty)
          _RecipientGroup(
            title: '⏳ ${l10n.filterQueued} (${detail.queuedRecipients.length})',
            recipients: detail.queuedRecipients,
            color: Colors.orange,
            theme: theme,
            l10n: l10n,
            startExpanded: detail.queuedRecipients.length <= 5,
          ),
      ],
    );
  }
}

// ── Recipient group (collapsible) ─────────────────────────────────────────────

class _RecipientGroup extends StatefulWidget {
  final String title;
  final List<RecipientDetail> recipients;
  final Color color;
  final ThemeData theme;
  final AppLocalizations l10n;
  final bool startExpanded;

  const _RecipientGroup({
    required this.title,
    required this.recipients,
    required this.color,
    required this.theme,
    required this.l10n,
    this.startExpanded = true,
  });

  @override
  State<_RecipientGroup> createState() => _RecipientGroupState();
}

class _RecipientGroupState extends State<_RecipientGroup>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  IconData _recipientIcon(String status) {
    if (status == 'delivered') return Icons.done_all;
    if (status == 'sent') return Icons.done;
    if (MessageStatusService.isFailed(status)) return Icons.cancel_outlined;
    if (status == 'received') return Icons.call_received;
    return Icons.hourglass_empty_outlined;
  }

  String _recipientStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'delivered':
        return l10n.statusDeliveredLabel;
      case 'sent':
        return l10n.statusSentLabel;
      case 'failed':
        return l10n.statusFailedLabel;
      case 'sending':
        return l10n.statusSendingLabel;
      case 'queued':
        return l10n.statusQueuedLabel;
      case 'received':
        return l10n.statusReceivedLabel;
      default:
        return l10n.statusUnknownLabel;
    }
  }

  static String _formatTime(int? epochSeconds) {
    if (epochSeconds == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = widget.l10n;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible list ──────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const Divider(height: 1),
                ...widget.recipients.asMap().entries.map((mapEntry) {
                  final i = mapEntry.key;
                  final recipient = mapEntry.value;
                  final isLast = i == widget.recipients.length - 1;
                  final timeLabel = _formatTime(recipient.updatedAt);
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        onTap: () {
                          final phone = recipient.phone;
                          if (phone.isEmpty) return;
                          final peerId = recipient.peerId ??
                              sl<NormalizationEngine>().peerIdFor(phone);
                          context.push(
                            '/messaging/conversation',
                            extra: {
                              'peerId': peerId,
                              'displayName': recipient.name,
                              'targetMessageId': recipient.messageId,
                            },
                          );
                        },
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: widget.color.withOpacity(0.1),
                          child: Icon(
                            _recipientIcon(recipient.status),
                            color: widget.color,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          recipient.name,
                          textDirection: recipient.name.startsWith('+') ||
                                  RegExp(r'^\d').hasMatch(recipient.name)
                              ? TextDirection.ltr
                              : null,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          recipient.phone,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _recipientStatusLabel(recipient.status, l10n),
                                style: TextStyle(
                                  color: widget.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (timeLabel.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                timeLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 56,
                          color: theme.colorScheme.outlineVariant
                              .withOpacity(0.4),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Retry banner ─────────────────────────────────────────────────────────────

class _RetryBanner extends ConsumerStatefulWidget {
  final String batchId;
  final int failedCount;
  final String channelType;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _RetryBanner({
    required this.batchId,
    required this.failedCount,
    required this.channelType,
    required this.theme,
    required this.l10n,
  });

  @override
  ConsumerState<_RetryBanner> createState() => _RetryBannerState();
}

class _RetryBannerState extends ConsumerState<_RetryBanner> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    try {
      final capService = sl<SmsCapabilityService>();
      final status = await capService.checkCanSend();
      if (!mounted) return;

      if (status == SmsCapabilityStatus.needsDefaultRole) {
        final accepted = await capService.requestDefaultSmsRole();
        if (!mounted) return;
        if (!accepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.l10n.defaultSmsRoleRequired)),
          );
          setState(() => _isRetrying = false);
          return;
        }
      }

      final smsRepo = sl<SmsRepository>();
      final result = await smsRepo.retryFailedSms(widget.batchId);
      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: widget.theme.colorScheme.error,
            ),
          );
        },
        (retryResult) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.l10n.isArabic
                    ? 'تمت إعادة محاولة إرسال ${retryResult.totalRetried} رسالة'
                    : 'Retried sending ${retryResult.totalRetried} message(s)',
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: widget.theme.colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${widget.failedCount} ${widget.channelType == 'whatsapp' ? widget.l10n.launchFailed.toLowerCase() : widget.l10n.sendFailed.toLowerCase()}',
                style: TextStyle(
                  color: widget.theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            if (widget.channelType == 'sms')
              FilledButton.icon(
                onPressed: _isRetrying ? null : _handleRetry,
                icon: _isRetrying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(widget.l10n.retryFailedN(widget.failedCount)),
              ),
          ],
        ),
      ),
    );
  }
}
