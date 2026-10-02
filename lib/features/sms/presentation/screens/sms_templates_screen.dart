import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';
import 'package:zexano_sms/shared/widgets/empty_state_view.dart';

final smsTemplatesProvider =
    FutureProvider<List<SmsTemplateItem>>((ref) async {
  final repo = sl<SmsRepository>();
  final result = await repo.listTemplates();
  return result.fold(
    (failure) => throw failure,
    (templates) => templates
        .map((t) => SmsTemplateItem(
              id: t.id,
              title: t.title,
              body: t.bodyContent,
            ))
        .toList(),
  );
});

class SmsTemplateItem {
  final String id;
  final String title;
  final String body;

  const SmsTemplateItem({
    required this.id,
    required this.title,
    required this.body,
  });
}

class SmsTemplatesScreen extends ConsumerWidget {
  const SmsTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(smsTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.templates),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48,
                    color: theme.colorScheme.error),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.errorOccurred,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(smsTemplatesProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return EmptyStateView(
              icon: Icons.article_outlined,
              title: l10n.noTemplates,
              subtitle: l10n.addTemplateSubtitle,
              actionLabel: l10n.addTemplate,
              onAction: () => context.push('/messaging/templates/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(smsTemplatesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: ListTile(
                    title: Text(
                      template.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      template.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.push(
                            '/messaging/templates/${template.id}/edit',
                          );
                        } else if (value == 'delete') {
                          _deleteTemplate(context, ref, template, l10n);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text(l10n.editTemplate),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20,
                                  color: theme.colorScheme.error),
                              const SizedBox(width: AppSpacing.sm),
                              Text(l10n.delete,
                                  style: TextStyle(
                                      color: theme.colorScheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => context.pop(template),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/messaging/templates/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    WidgetRef ref,
    SmsTemplateItem template,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = sl<SmsRepository>();
    final result = await repo.deleteTemplate(template.id);
    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (_) {
        ref.invalidate(smsTemplatesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.templateDeleted)),
        );
      },
    );
  }
}
