import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/sms/domain/entities/sms_message.dart';
import 'package:zexano_sms/features/sms/presentation/providers/sms_providers.dart';
import 'package:zexano_sms/shared/widgets/primary_button.dart';

final smsDetailProvider =
    FutureProvider.family<SmsDetailData, String>((ref, id) async {
  final repo = ref.watch(smsRepositoryProvider);
  final messageResult = await repo.getSmsById(id);
  final message = messageResult.fold(
    (failure) => throw failure,
    (sms) => sms,
  );

  final batchResult = await repo.calculateBatchResult(id);
  final batch = batchResult.fold(
    (failure) => throw failure,
    (result) => result,
  );

  return SmsDetailData(message: message, failedPhones: batch.failedPhoneNumbers);
});

class SmsDetailData {
  final SmsMessage message;
  final List<String> failedPhones;

  const SmsDetailData({
    required this.message,
    required this.failedPhones,
  });
}

class SmsDetailScreen extends ConsumerWidget {
  final String messageId;

  const SmsDetailScreen({super.key, required this.messageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final detailAsync = ref.watch(smsDetailProvider(messageId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.messageDetail),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.errorOccurred,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: l10n.retry,
                  onPressed: () =>
                      ref.invalidate(smsDetailProvider(messageId)),
                ),
              ],
            ),
          ),
        ),
        data: (detail) => _SmsDetailContent(
          detail: detail,
          onRetry: () async {
            final repo = ref.read(smsRepositoryProvider);
            final result = await repo.retryFailedSms(messageId);
            if (!context.mounted) return;
            result.fold(
              (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(failure.message),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              },
              (retryResult) {
                ref.invalidate(smsDetailProvider(messageId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${l10n.retrySuccess} — ${retryResult.succeeded}/${retryResult.totalRetried}',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SmsDetailContent extends StatelessWidget {
  final SmsDetailData detail;
  final VoidCallback onRetry;

  const _SmsDetailContent({
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final message = detail.message;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _StatusHeader(message: message, l10n: l10n, theme: theme),
        const SizedBox(height: AppSpacing.lg),
        _Section(title: l10n.messageBody, child: _MessageBody(message: message, theme: theme)),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: l10n.status,
          child: _StatusSummary(message: message, l10n: l10n, theme: theme),
        ),
        if (detail.failedPhones.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.retryFailed,
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _Section(
          title: '${l10n.recipientsLabel} (${message.totalRecipients})',
          child: Column(
            children: [
              _RecipientCountRow(
                icon: Icons.check_circle,
                label: l10n.sent,
                count: message.sentCount,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              _RecipientCountRow(
                icon: Icons.cancel,
                label: l10n.failed,
                count: message.failedCount,
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final SmsMessage message;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _StatusHeader({
    required this.message,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final IconData statusIcon;
    switch (message.status) {
      case 'sent':
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.cancel;
        break;
      case 'partial':
        statusColor = theme.colorScheme.tertiary;
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.schedule;
    }

    String statusLabel;
    switch (message.status) {
      case 'sent':
        statusLabel = l10n.sent;
        break;
      case 'failed':
        statusLabel = l10n.failed;
        break;
      case 'partial':
        statusLabel = l10n.partial;
        break;
      default:
        statusLabel = l10n.queued;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 40, color: statusColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _formatDate(message.createdAt, l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (message.sentAt != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${l10n.sentAt} ${_formatDate(message.sentAt!, l10n)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(int epochSeconds, AppLocalizations l10n) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MessageBody extends StatelessWidget {
  final SmsMessage message;
  final ThemeData theme;

  const _MessageBody({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        message.messageBody,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  final SmsMessage message;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _StatusSummary({
    required this.message,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.people_outline,
          label: '${message.totalRecipients}',
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          icon: Icons.check_circle_outline,
          label: '${message.sentCount}',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          icon: Icons.error_outline,
          label: '${message.failedCount}',
          color: theme.colorScheme.error,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _RecipientCountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _RecipientCountRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          '$count',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
