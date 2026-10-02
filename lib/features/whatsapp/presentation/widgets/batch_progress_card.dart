import 'package:flutter/material.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/whatsapp/domain/models/assisted_batch_progress.dart';

class BatchProgressCard extends StatelessWidget {
  final AssistedBatchProgress progress;
  final AppLocalizations l10n;
  final ThemeData theme;

  const BatchProgressCard({
    super.key,
    required this.progress,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final percent = progress.progressPercent;
    final statusLabel = _statusLabel();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.batchProgress,
                  style: theme.textTheme.titleMedium,
                ),
                Chip(
                  label: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _statusColor(),
                    ),
                  ),
                  backgroundColor: _statusColor().withOpacity(0.1),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor:
                    theme.colorScheme.surfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(Icons.check_circle_outline,
                    '${progress.completed}', theme.colorScheme.primary),
                _stat(Icons.error_outline,
                    '${progress.failed}', theme.colorScheme.error),
                _stat(Icons.schedule, '${progress.remaining}',
                    theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _statusLabel() {
    switch (progress.status) {
      case 'completed':
        return l10n.completed;
      case 'cancelled':
        return l10n.batchCancelled;
      default:
        return l10n.inProgress;
    }
  }

  Color _statusColor() {
    switch (progress.status) {
      case 'completed':
        return theme.colorScheme.primary;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.tertiary;
    }
  }
}
