import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/whatsapp/presentation/controllers/assisted_batch_notifier.dart';
import 'package:zexano_sms/features/whatsapp/presentation/widgets/batch_progress_card.dart';

class WhatsAppBatchProgressScreen extends ConsumerWidget {
  final String sessionId;

  const WhatsAppBatchProgressScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final batchState = ref.watch(assistedBatchProvider);
    final notifier = ref.read(assistedBatchProvider.notifier);

    final progress = batchState.progress;
    final currentRecipient = batchState.currentRecipient;

    if (progress.status == 'idle') {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.batchProgress)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.batchProgress),
        actions: [
          if (progress.status == 'in_progress')
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.cancel,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.confirmCancelBatch),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l10n.confirm),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  notifier.cancelSession();
                  context.pop();
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BatchProgressCard(progress: progress, l10n: l10n, theme: theme),
            const SizedBox(height: AppSpacing.lg),
            if (progress.status == 'completed')
              _buildCompleted(context, l10n, theme),
            if (progress.status == 'cancelled')
              _buildCancelled(context, l10n, theme),
            if (progress.status == 'in_progress' && currentRecipient != null)
              _buildRecipientCard(
                  currentRecipient, notifier, l10n, theme, batchState),
            if (progress.status == 'in_progress' && currentRecipient == null)
              const Center(child: CircularProgressIndicator()),
            if (batchState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 20,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          batchState.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: notifier.clearError,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientCard(
    dynamic recipient,
    AssistedBatchNotifier notifier,
    AppLocalizations l10n,
    ThemeData theme,
    AssistedBatchState batchState,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.currentRecipient,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipient.contactName.isNotEmpty)
                    Text(
                      recipient.contactName,
                      style: theme.textTheme.titleMedium,
                    ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    recipient.phoneNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.sendManuallyInWhatsApp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    batchState.isLaunching ? null : () => notifier.launchCurrent(),
                icon: batchState.isLaunching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.open_in_new),
                label: Text(l10n.launchWhatsApp),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => notifier.markSent(),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.markSent),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => notifier.skipCurrent(),
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: Text(l10n.skip),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle,
            size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.batchComplete,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.done),
        ),
      ],
    );
  }

  Widget _buildCancelled(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cancel_outlined,
            size: 64, color: theme.colorScheme.error),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.batchCancelled,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}
