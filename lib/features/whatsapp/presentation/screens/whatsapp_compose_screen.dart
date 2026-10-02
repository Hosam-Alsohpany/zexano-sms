import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/staged_recipient.dart';
import 'package:zexano_sms/features/whatsapp/domain/repositories/whatsapp_repository.dart';
import 'package:zexano_sms/features/whatsapp/presentation/controllers/assisted_batch_notifier.dart';
import 'package:zexano_sms/features/whatsapp/presentation/widgets/recipient_chip.dart';

class WhatsAppComposeScreen extends ConsumerStatefulWidget {
  const WhatsAppComposeScreen({super.key});

  @override
  ConsumerState<WhatsAppComposeScreen> createState() =>
      _WhatsAppComposeScreenState();
}

class _WhatsAppComposeScreenState
    extends ConsumerState<WhatsAppComposeScreen> {
  final _bodyController = TextEditingController();
  List<StagedRecipient> _recipients = [];
  bool _isStaging = false;
  String? _errorMessage;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  int get _characterCount => _bodyController.text.length;

  Future<void> _selectRecipients() async {
    final result = await context.push<List<StagedRecipient>>(
      '/whatsapp/recipients',
    );
    if (result != null && mounted) {
      setState(() => _recipients = result);
    }
  }

  void _removeRecipient(int index) {
    setState(() => _recipients.removeAt(index));
  }

  Future<void> _startBatch() async {
    final l10n = AppLocalizations.of(context);

    if (_bodyController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.messageEmptyWarning);
      return;
    }

    if (_recipients.isEmpty) {
      setState(() => _errorMessage = l10n.noRecipientsWarning);
      return;
    }

    setState(() {
      _isStaging = true;
      _errorMessage = null;
    });

    final repo = sl<WhatsAppRepository>();
    final phones = _recipients.map((r) => r.phoneNumber).toList();
    final result = await repo.stageBulkMessages(
      messageBody: _bodyController.text.trim(),
      phoneNumbers: phones,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isStaging = false;
          _errorMessage = failure.message;
        });
      },
      (session) {
        setState(() => _isStaging = false);
        ref.read(assistedBatchProvider.notifier).startSession(session);
        context.push('/whatsapp/batch/${session.sessionId}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.whatsappCompose),
        actions: [
          TextButton(
            onPressed: _isStaging ? null : _startBatch,
            child: _isStaging
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.startBatch,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.assistedFlowDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.messageBody,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              maxLength: 1600,
              decoration: InputDecoration(
                hintText: l10n.typeMessageHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Row(
                children: [
                  Text(
                    '$_characterCount ${l10n.characters}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.recipientsLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _selectRecipients,
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: Text(l10n.selectRecipients),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_recipients.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: Text(
                    l10n.noRecipientsWarning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: List.generate(_recipients.length, (i) {
                  final r = _recipients[i];
                  return RecipientChip(
                    label: r.contactName.isNotEmpty
                        ? r.contactName
                        : r.phoneNumber,
                    onRemove: () => _removeRecipient(i),
                  );
                }),
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 20, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
