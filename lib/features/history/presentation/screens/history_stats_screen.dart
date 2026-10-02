import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/history/presentation/providers/history_providers.dart';

class HistoryStatsScreen extends ConsumerStatefulWidget {
  const HistoryStatsScreen({super.key});

  @override
  ConsumerState<HistoryStatsScreen> createState() => _HistoryStatsScreenState();
}

class _HistoryStatsScreenState extends ConsumerState<HistoryStatsScreen> {
  int _totalAll = 0;
  int _totalFailed = 0;
  int _totalRetryable = 0;
  int _totalSms = 0;
  int _totalWa = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(historyRepositoryProvider);
      final results = await Future.wait([
        repo.listMessageHistory(),
        repo.listFailedHistory(),
        repo.listRetryableHistory(),
        repo.filterHistoryByChannel('sms'),
        repo.filterHistoryByChannel('whatsapp'),
      ]);
      setState(() {
        _totalAll = results[0].fold((f) => 0, (list) => list.length);
        _totalFailed = results[1].fold((f) => 0, (list) => list.length);
        _totalRetryable = results[2].fold((f) => 0, (list) => list.length);
        _totalSms = results[3].fold((f) => 0, (list) => list.length);
        _totalWa = results[4].fold((f) => 0, (list) => list.length);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyStats),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(l10n.errorOccurred))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _StatCard(
                        icon: Icons.history,
                        label: l10n.history,
                        value: '$_totalAll',
                        theme: theme,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        icon: Icons.sms,
                        label: l10n.smsOnly,
                        value: '$_totalSms',
                        theme: theme,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        icon: Icons.chat_bubble_outline,
                        label: l10n.whatsappOnly,
                        value: '$_totalWa',
                        theme: theme,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        icon: Icons.error_outline,
                        label: l10n.failedEntries,
                        value: '$_totalFailed',
                        theme: theme,
                        valueColor: theme.colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StatCard(
                        icon: Icons.replay,
                        label: l10n.retryableEntries,
                        value: '$_totalRetryable',
                        theme: theme,
                        valueColor: theme.colorScheme.tertiary,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: (valueColor ?? theme.colorScheme.primary)
                  .withOpacity(0.1),
              child: Icon(
                icon,
                color: valueColor ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: theme.textTheme.bodyLarge,
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
