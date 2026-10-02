import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_colors.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/features/backup/presentation/controllers/restore_notifier.dart';

class RestoreResultScreen extends ConsumerWidget {
  const RestoreResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(restoreNotifierProvider);

    if (state.step == RestoreStep.error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restore Failed')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 80, color: theme.colorScheme.error),
                const SizedBox(height: AppSpacing.lg),
                Text('Restore failed',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.errorMessage ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => context.go('/settings'),
                  child: const Text('Back to Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final report = state.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              report != null && report.hasFailures
                  ? Icons.warning_amber
                  : Icons.check_circle,
              size: 80,
              color: report != null && report.hasFailures
                  ? AppColors.warning
                  : AppColors.success,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              report != null && report.hasFailures
                  ? 'Restore completed with warnings'
                  : 'Data restored successfully',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (report != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _ResultRow(
                        icon: Icons.contacts,
                        label: 'Contacts restored',
                        count: report.restoredContactCount,
                      ),
                      const Divider(),
                      _ResultRow(
                        icon: Icons.sms,
                        label: 'SMS messages restored',
                        count: report.restoredSmsCount,
                      ),
                      const Divider(),
                      _ResultRow(
                        icon: Icons.chat,
                        label: 'WhatsApp sessions restored',
                        count: report.restoredWaCount,
                      ),
                      const Divider(),
                      _ResultRow(
                        icon: Icons.warning,
                        label: 'Failed items',
                        count: report.failedItems,
                        isError: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (report.warnings.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Warnings', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                ...report.warnings.map(
                  (w) => Card(
                    color: AppColors.warningContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              size: 20, color: AppColors.onWarningContainer),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(w,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onWarningContainer,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.home),
              label: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isError;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.count,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon,
              size: 24,
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label)),
          Text(
            count.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
