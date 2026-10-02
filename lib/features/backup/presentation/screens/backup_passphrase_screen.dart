import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/config/design_system/app_colors.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/features/backup/presentation/controllers/backup_notifier.dart';

class BackupPassphraseScreen extends ConsumerWidget {
  const BackupPassphraseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(createBackupNotifierProvider);
    final notifier = ref.read(createBackupNotifierProvider.notifier);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final canProceed = state.isEncrypted
        ? (state.passphrase.length >= 8 && state.passphrase == state.passphraseConfirm)
        : true;

    return Scaffold(
      appBar: AppBar(title: const Text('Encryption Passphrase')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Set a passphrase to encrypt your backup',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This passphrase will be required to restore the backup. '
              'If you lose it, the backup cannot be recovered.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.warning,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              decoration: InputDecoration(
                labelText: 'Passphrase',
                helperText: 'At least 8 characters',
                prefixIcon: const Icon(Icons.key),
              ),
              obscureText: true,
              onChanged: notifier.setPassphrase,
            ),
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: canProceed ? notifier.createBackup : null,
              icon: Icon(isRtl ? Icons.arrow_back : Icons.arrow_forward),
              label: const Text('Create Backup'),
            ),
            if (state.step == BackupFlowStep.error) ...[
              const SizedBox(height: AppSpacing.lg),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: theme.colorScheme.error),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          state.errorMessage ?? 'Unknown error',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (state.isCreating) ...[
              const SizedBox(height: AppSpacing.xl),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text('Creating encrypted backup...',
                    style: theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
