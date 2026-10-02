import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_colors.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/features/backup/presentation/controllers/restore_notifier.dart';

class RestorePreviewScreen extends ConsumerWidget {
  const RestorePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(restoreNotifierProvider);
    final notifier = ref.read(restoreNotifierProvider.notifier);
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    ref.listen(restoreNotifierProvider, (prev, next) {
      if (next.step == RestoreStep.completed) {
        context.pushReplacement('/backup/restore/result');
      }
    });

    if (state.step == RestoreStep.selecting && args != null) {
      notifier.selectBackupFile(
        args['filePath'] as String,
        args['fileName'] as String,
        args['isEncrypted'] as bool,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Restore Preview')),
      body: _buildBody(context, theme, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    RestoreFlowState state,
    RestoreNotifier notifier,
  ) {
    if (state.step == RestoreStep.validating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.lg),
            Text('Validating backup file...'),
          ],
        ),
      );
    }

    if (state.step == RestoreStep.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: AppSpacing.lg),
              Text(state.errorMessage ?? 'Validation failed',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final preview = state.preview;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Backup contents', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          if (preview != null) ...[
            _StatRow(
              icon: Icons.contacts,
              label: 'Contacts',
              count: preview.contactCount,
            ),
            _StatRow(
              icon: Icons.sms,
              label: 'SMS Messages',
              count: preview.smsMessageCount,
            ),
            _StatRow(
              icon: Icons.chat,
              label: 'WhatsApp Sessions',
              count: preview.whatsAppSessionCount,
            ),
            _StatRow(
              icon: Icons.group,
              label: 'Groups',
              count: preview.groupCount,
            ),
            _StatRow(
              icon: Icons.description,
              label: 'Templates',
              count: preview.templateCount,
            ),
            const Divider(height: AppSpacing.xl),
            _StatRow(
              icon: Icons.summarize,
              label: 'Total entries',
              count: preview.totalEntries,
              isTotal: true,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Card(
            color: AppColors.warningContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber,
                      color: AppColors.onWarningContainer),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Destructive operation',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.onWarningContainer,
                            )),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Restoring this backup will replace ALL existing data. '
                          'Current contacts, messages, and history will be overwritten. '
                          'Make sure you have a current backup of your existing data.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onWarningContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.isEncrypted) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Enter passphrase to decrypt',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Passphrase',
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              onChanged: notifier.setPassphrase,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              decoration: InputDecoration(
                labelText: 'Confirm passphrase',
                prefixIcon: const Icon(Icons.key),
                errorText: state.passphraseConfirm.isNotEmpty &&
                        state.passphrase != state.passphraseConfirm
                    ? 'Passphrases do not match'
                    : null,
              ),
              obscureText: true,
              onChanged: notifier.setPassphraseConfirm,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: state.canConfirm ? () => _showConfirmDialog(context, notifier) : null,
            icon: const Icon(Icons.restore),
            label: const Text('Restore Data'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
          ),
          if (state.step == RestoreStep.restoring) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: AppSpacing.md),
            const Center(child: Text('Restoring data...')),
          ],
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, RestoreNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Destructive Restore'),
        content: const Text(
          'This will replace ALL your current data with the backup contents. '
          'This action CANNOT be undone. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.confirmDestructive();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Yes, Restore'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isTotal;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.count,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon,
              size: 24,
              color: isTotal
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: isTotal
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            count.toString(),
            style: (isTotal
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyLarge)
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
