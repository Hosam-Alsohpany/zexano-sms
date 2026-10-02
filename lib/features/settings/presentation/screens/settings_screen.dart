import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/settings_providers.dart';
import 'language_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'messaging_preferences_screen.dart';
import 'backup_settings_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => ref.invalidate(settingsProvider),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (_) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SectionHeader(l10n.settingsSectionGeneral),
            _SettingsTile(
              icon: Icons.language,
              title: l10n.settingsLanguage,
              subtitle: l10n.settingsLanguageSubtitle,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())),
            ),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: l10n.settingsTheme,
              subtitle: l10n.settingsThemeSubtitle,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThemeSettingsScreen())),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(l10n.settingsSectionMessaging),
            _SettingsTile(
              icon: Icons.speed,
              title: l10n.settingsSmsThrottle,
              subtitle: l10n.settingsSmsThrottleSubtitle,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagingPreferencesScreen())),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(l10n.settingsSectionBackup),
            _SettingsTile(
              icon: Icons.backup_outlined,
              title: l10n.settingsBackup,
              subtitle: l10n.settingsBackupSubtitle,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupSettingsScreen())),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(l10n.settingsSectionAbout),
            _SettingsTile(
              icon: Icons.info_outline,
              title: l10n.settingsAbout,
              subtitle: l10n.settingsAboutSubtitle,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
