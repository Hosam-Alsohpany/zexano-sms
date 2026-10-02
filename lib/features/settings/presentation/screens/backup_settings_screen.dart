import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/settings_providers.dart';

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.settingsBackup),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(settingsProvider),
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SwitchListTile(
              title: Text(l10n.settingsAutoBackup),
              subtitle: Text(l10n.settingsAutoBackupDesc),
              value: settings.autoBackupEnabled,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setBackupPreferences(autoBackupEnabled: v),
            ),
            const Divider(height: 1),
            if (settings.autoBackupEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsBackupInterval,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [1, 3, 7, 14, 30].map((days) {
                        final selected =
                            settings.autoBackupIntervalDays == days;
                        return ChoiceChip(
                          label: Text('$days ${l10n.settingsDaysLabel}'),
                          selected: selected,
                          onSelected: selected
                              ? null
                              : (_) => ref
                                  .read(settingsProvider.notifier)
                                  .setBackupPreferences(
                                      autoBackupIntervalDays: days),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            CheckboxListTile(
              title: Text(l10n.settingsIncludeSms),
              value: settings.backupIncludeSms,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setBackupPreferences(includeSms: v),
            ),
            CheckboxListTile(
              title: Text(l10n.settingsIncludeWhatsApp),
              value: settings.backupIncludeWhatsApp,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setBackupPreferences(includeWhatsApp: v),
            ),
            CheckboxListTile(
              title: Text(l10n.settingsIncludeContacts),
              value: settings.backupIncludeContacts,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setBackupPreferences(includeContacts: v),
            ),
          ],
        ),
      ),
    );
  }
}
