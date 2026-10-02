import 'package:flutter/material.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';

class RecipientChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;

  const RecipientChip({
    super.key,
    required this.label,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        label,
        style: theme.textTheme.labelSmall,
        overflow: TextOverflow.ellipsis,
      ),
      deleteIcon: onRemove != null
          ? const Icon(Icons.close, size: 16)
          : null,
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
  }
}
