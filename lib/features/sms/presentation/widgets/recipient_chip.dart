import 'package:flutter/material.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_recipient.dart';

class RecipientChip extends StatelessWidget {
  final SmsRecipient recipient;
  final VoidCallback? onRemove;

  const RecipientChip({
    super.key,
    required this.recipient,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      avatar: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          recipient.contactName.isNotEmpty
              ? recipient.contactName[0].toUpperCase()
              : '#',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      label: Text(
        recipient.contactName.isNotEmpty
            ? recipient.contactName
            : recipient.phoneNumber,
        style: theme.textTheme.bodySmall,
        textDirection: recipient.contactName.isNotEmpty
            ? null
            : TextDirection.ltr,
      ),
      deleteIcon: onRemove != null
          ? const Icon(Icons.close, size: 16)
          : null,
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class RecipientStatusTile extends StatelessWidget {
  final SmsRecipient recipient;

  const RecipientStatusTile({
    super.key,
    required this.recipient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color statusColor;
    final IconData statusIcon;
    switch (recipient.status) {
      case 'sent':
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.schedule;
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: statusColor.withOpacity(0.12),
        child: Icon(statusIcon, size: 18, color: statusColor),
      ),
      title: Text(
        recipient.contactName.isNotEmpty
            ? recipient.contactName
            : recipient.phoneNumber,
        style: theme.textTheme.bodyMedium,
        textDirection: recipient.contactName.isNotEmpty
            ? null
            : TextDirection.ltr,
      ),
      subtitle: Text(
        recipient.phoneNumber,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textDirection: TextDirection.ltr,
      ),
      trailing: Text(
        recipient.status,
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
