import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/features/backup/presentation/controllers/backup_notifier.dart';

class CreateBackupScreen extends ConsumerWidget {
  const CreateBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(createBackupNotifierProvider);
    final notifier = ref.read(createBackupNotifierProvider.notifier);

    ref.listen(createBackupNotifierProvider, (prev, next) {
      if (next.step == BackupFlowStep.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
        context.pop(true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Create Backup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose backup type',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            _BackupTypeCard(
              icon: Icons.storage,
              title: 'Full SQLite Backup',
              subtitle:
                  'Complete database backup. Faster, smaller. Not human-readable.',
              isSelected: !state.isEncrypted,
              onTap: notifier.setNotEncrypted,
            ),
            const SizedBox(height: AppSpacing.md),
            _BackupTypeCard(
              icon: Icons.lock_outline,
              title: 'Encrypted JSON Backup',
              subtitle:
                  'Portable format with AES-256 encryption. Select what to include.',
              isSelected: state.isEncrypted,
              onTap: () => notifier.setEncrypted(true),
            ),
            if (state.step == BackupFlowStep.configuration) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Include data', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _IncludeOption(
                icon: Icons.sms,
                label: 'SMS Messages',
                value: state.includeSms,
                onChanged: (_) => notifier.toggleSms(),
              ),
              _IncludeOption(
                icon: Icons.chat,
                label: 'WhatsApp Sessions',
                value: state.includeWhatsApp,
                onChanged: (_) => notifier.toggleWhatsApp(),
              ),
              _IncludeOption(
                icon: Icons.contacts,
                label: 'Contacts & Groups',
                value: state.includeContacts,
                onChanged: (_) => notifier.toggleContacts(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: state.canProceedFromConfig
                    ? notifier.goToPassphrase
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Set Passphrase'),
              ),
            ],
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
                child: Text('Creating backup...',
                    style: theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BackupTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _BackupTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon,
                  size: 40,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncludeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _IncludeOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}
