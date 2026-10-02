import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/value_objects/sms_throttle_interval.dart';
import '../providers/settings_providers.dart';

class MessagingPreferencesScreen extends ConsumerWidget {
  const MessagingPreferencesScreen({super.key});

  static const List<int> _throttleOptions = [0, 1, 2, 3, 5, 10, 30, 60];

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
        title: Text(l10n.settingsSmsThrottle),
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
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                l10n.settingsThrottleDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Card(
              child: Column(
                children: _throttleOptions.map((seconds) {
                      return RadioListTile<int>(
                    title: Text(_throttleLabel(seconds, l10n)),
                    value: seconds,
                    groupValue: settings.smsThrottleInterval.inSeconds,
                    onChanged: (value) {
                      if (value != null) {
                        final interval =
                            SmsThrottleInterval.fromSeconds(value);
                        ref
                            .read(settingsProvider.notifier)
                            .setSmsThrottleInterval(interval);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _throttleLabel(int seconds, AppLocalizations l10n) {
    if (seconds == 0) return l10n.settingsThrottleNone;
    return '$seconds ${l10n.settingsThrottleSeconds}';
  }
}
