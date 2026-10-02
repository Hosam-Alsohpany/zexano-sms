import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/value_objects/theme_option.dart';
import '../providers/settings_providers.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

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
        title: Text(l10n.settingsTheme),
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
          children: [
            _ThemeOption(
              icon: Icons.light_mode,
              label: l10n.settingsThemeLight,
              selected: settings.themeOption.isLight,
              onTap: () => _select(ref, ThemeOption.light),
            ),
            _ThemeOption(
              icon: Icons.dark_mode,
              label: l10n.settingsThemeDark,
              selected: settings.themeOption.isDark,
              onTap: () => _select(ref, ThemeOption.dark),
            ),
            _ThemeOption(
              icon: Icons.brightness_auto,
              label: l10n.settingsThemeSystem,
              selected: settings.themeOption.isSystem,
              onTap: () => _select(ref, ThemeOption.system),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(WidgetRef ref, ThemeOption option) async {
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setTheme(option);
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: selected ? null : onTap,
    );
  }
}
