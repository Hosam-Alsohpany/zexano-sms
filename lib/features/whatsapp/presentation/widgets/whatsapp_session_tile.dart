import 'package:flutter/material.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/assisted_session.dart';

class WhatsAppSessionTile extends StatelessWidget {
  final AssistedSession session;
  final VoidCallback? onTap;

  const WhatsAppSessionTile({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final statusColor = session.isCompleted
        ? theme.colorScheme.primary
        : session.isCancelled
            ? theme.colorScheme.error
            : theme.colorScheme.tertiary;

    final statusIcon = session.isCompleted
        ? Icons.check_circle
        : session.isCancelled
            ? Icons.cancel
            : Icons.schedule;

    final date = DateTime.fromMillisecondsSinceEpoch(
        session.createdAt * 1000);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          session.messageBody,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '$dateStr  |  ${session.completedRecipients}/${session.totalRecipients}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          _statusLabel(session, l10n),
          style: theme.textTheme.labelSmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _statusLabel(AssistedSession session, AppLocalizations l10n) {
    if (session.isCompleted) return l10n.completed;
    if (session.isCancelled) return l10n.batchCancelled;
    return l10n.inProgress;
  }
}
