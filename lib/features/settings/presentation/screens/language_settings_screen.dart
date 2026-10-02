import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/value_objects/language_code.dart';
import '../providers/settings_providers.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

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
        title: Text(l10n.settingsLanguage),
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
            _LanguageOption(
              code: 'en',
              label: l10n.settingsEnglish,
              subtitle: 'English',
              selected: settings.languageCode.isEnglish,
              onTap: () => _select(ref, LanguageCode.english),
            ),
            _LanguageOption(
              code: 'ar',
              label: l10n.settingsArabic,
              subtitle: 'العربية',
              selected: settings.languageCode.isArabic,
              onTap: () => _select(ref, LanguageCode.arabic),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(WidgetRef ref, LanguageCode code) async {
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setLanguage(code);
  }
}

class _LanguageOption extends StatelessWidget {
  final String code;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.code,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.language : Icons.language_outlined,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      subtitle: Text(subtitle),
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
