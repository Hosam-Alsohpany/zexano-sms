import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/backup/domain/entities/backup_metadata.dart';
import 'package:zexano_sms/features/backup/presentation/controllers/backup_notifier.dart';
import 'package:zexano_sms/features/backup/presentation/widgets/backup_card.dart';
import 'package:zexano_sms/features/backup/presentation/widgets/empty_backup_state.dart';

class BackupHomeScreen extends ConsumerWidget {
  const BackupHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final listState = ref.watch(backupListNotifierProvider);

    ref.listen(backupListNotifierProvider, (prev, next) {
      if (next.status == BackupListStatus.initial) {
        ref.read(backupListNotifierProvider.notifier).loadBackups();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(backupListNotifierProvider.notifier).loadBackups(),
          ),
        ],
      ),
      body: _buildBody(context, ref, l10n, theme, listState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(context, ref),
        icon: const Icon(Icons.backup),
        label: const Text('Create Backup'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    BackupListState listState,
  ) {
    switch (listState.status) {
      case BackupListStatus.initial:
      case BackupListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case BackupListStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                listState.errorMessage ?? l10n.errorOccurred,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(backupListNotifierProvider.notifier).loadBackups(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        );
      case BackupListStatus.loaded:
        if (listState.backups.isEmpty) {
          return const EmptyBackupState();
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(backupListNotifierProvider.notifier).loadBackups(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: listState.backups.length,
            itemBuilder: (context, index) {
              final backup = listState.backups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: BackupCard(
                  metadata: backup,
                  onTap: () => _onBackupTap(context, backup),
                  onDelete: () => _confirmDelete(context, ref, backup),
                ),
              );
            },
          ),
        );
    }
  }

  void _showCreateOptions(BuildContext context, WidgetRef ref) {
    ref.read(createBackupNotifierProvider.notifier).reset();
    context.pushNamed('backup-create');
  }

  void _onBackupTap(
    BuildContext context,
    BackupMetadata backup,
  ) {
    context.pushNamed('backup-restore-preview', extra: {
      'filePath': backup.fileName,
      'fileName': backup.fileName,
      'isEncrypted': backup.isEncrypted,
    });
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BackupMetadata backup,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Delete "${backup.fileName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(backupListNotifierProvider.notifier)
                  .deleteBackup(backup.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
