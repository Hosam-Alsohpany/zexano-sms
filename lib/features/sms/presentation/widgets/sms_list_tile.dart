import 'package:flutter/material.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/sms/domain/entities/sms_message.dart';

class SmsListTile extends StatelessWidget {
  final SmsMessage message;
  final VoidCallback onTap;

  const SmsListTile({
    super.key,
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor(theme).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  _statusIcon,
                  size: 20,
                  color: _statusColor(theme),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.messageBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${message.sentCount}/${message.totalRecipients} ${l10n.recipientsLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _formatDate(message.createdAt, l10n),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusBadge(
                label: _statusLabel(l10n),
                color: _statusColor(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _statusIcon {
    switch (message.status) {
      case 'sent':
        return Icons.check_circle_outline;
      case 'failed':
        return Icons.error_outline;
      case 'partial':
        return Icons.warning_amber_outlined;
      case 'queued':
        return Icons.hourglass_empty_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _statusColor(ThemeData theme) {
    switch (message.status) {
      case 'sent':
        return theme.colorScheme.primary;
      case 'failed':
        return theme.colorScheme.error;
      case 'partial':
        return theme.colorScheme.tertiary;
      case 'queued':
        return theme.colorScheme.onSurfaceVariant;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (message.status) {
      case 'sent':
        return l10n.sent;
      case 'failed':
        return l10n.failed;
      case 'partial':
        return l10n.partial;
      case 'queued':
        return l10n.queued;
      default:
        return message.status;
    }
  }

  String _formatDate(int epochSeconds, AppLocalizations l10n) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
