import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/backup/domain/entities/backup_metadata.dart';
import 'package:zexano_sms/features/backup/presentation/providers/backup_providers.dart';
import 'package:zexano_sms/features/backup/presentation/widgets/backup_card.dart';

class RestoreImportScreen extends ConsumerStatefulWidget {
  const RestoreImportScreen({super.key});

  @override
  ConsumerState<RestoreImportScreen> createState() => _RestoreImportScreenState();
}

class _RestoreImportScreenState extends ConsumerState<RestoreImportScreen> {
  List<_BackupFileInfo> _backupFiles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  void _confirmDelete(BuildContext context, _BackupFileInfo info) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteBackup),
        content: Text(l10n.deleteBackupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteFile(info.filePath);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      await File(filePath).delete();
      _loadBackupFiles();
    } catch (_) {}
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backups');
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
        setState(() {
          _backupFiles = [];
          _loading = false;
        });
        return;
      }
      final repo = ref.read(backupRepositoryProvider);
      final files = backupDir.listSync().whereType<File>().toList();
      final infos = <_BackupFileInfo>[];
      for (final file in files) {
        final outcome = await repo.readBackupMetadata(file.path);
        outcome.fold(
          (_) {},
          (meta) => infos.add(_BackupFileInfo(
            filePath: file.path,
            fileName: meta.fileName,
            createdAt: meta.createdAt,
            fileSize: meta.fileSize,
            entryCount: meta.entryCount,
            isEncrypted: meta.isEncrypted,
          )),
        );
      }
      infos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _backupFiles = infos;
        _loading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Restore from Backup')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: AppSpacing.lg),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: _loadBackupFiles,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _backupFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.backup_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.4)),
                          const SizedBox(height: AppSpacing.lg),
                          Text('No backup files found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Create a backup first, then return here to restore.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBackupFiles,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _backupFiles.length,
                        itemBuilder: (context, index) {
                          final info = _backupFiles[index];
                          final metadata = BackupMetadata(
                            id: info.filePath,
                            fileName: info.fileName,
                            createdAt: info.createdAt,
                            fileSize: info.fileSize,
                            entryCount: info.entryCount,
                            checksum: '',
                            isEncrypted: info.isEncrypted,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: BackupCard(
                              metadata: metadata,
                              onTap: () {
                                context.pushNamed(
                                  'backup-restore-preview',
                                  extra: {
                                    'filePath': info.filePath,
                                    'fileName': info.fileName,
                                    'isEncrypted': info.isEncrypted,
                                  },
                                );
                              },
                               onDelete: () => _confirmDelete(context, info),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _BackupFileInfo {
  final String filePath;
  final String fileName;
  final int createdAt;
  final int fileSize;
  final int entryCount;
  final bool isEncrypted;

  const _BackupFileInfo({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.fileSize,
    required this.entryCount,
    required this.isEncrypted,
  });
}
