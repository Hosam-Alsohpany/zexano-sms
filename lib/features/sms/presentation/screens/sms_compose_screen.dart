import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/core/phone/phone_validator.dart';
import 'package:zexano_sms/core/utils/sms_logger.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_recipient.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';
import 'package:zexano_sms/features/sms/domain/value_objects/sms_payload.dart';
import 'package:zexano_sms/features/sms/presentation/widgets/recipient_chip.dart';

class SmsComposeScreen extends ConsumerStatefulWidget {
  const SmsComposeScreen({super.key});

  @override
  ConsumerState<SmsComposeScreen> createState() => _SmsComposeScreenState();
}

class _SmsComposeScreenState extends ConsumerState<SmsComposeScreen> {
  static const _smsChannel = MethodChannel('com.zexano.sms/sms');

  final _bodyController = TextEditingController();
  List<SmsRecipient> _recipients = [];
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  int get _characterCount => _bodyController.text.length;
  int get _estimatedSegments =>
      SmsPayload.calculateSegments(_bodyController.text);

  Future<void> _selectRecipients() async {
    final result = await context.push<List<SmsRecipient>>(
      '/messaging/recipients',
    );
    if (result != null && mounted) {
      setState(() => _recipients = result);
    }
  }

  void _removeRecipient(int index) {
    setState(() => _recipients.removeAt(index));
  }

  Future<bool> _isDefaultSmsApp() async {
    try {
      return await _smsChannel.invokeMethod<bool>('isDefaultSmsApp') ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<bool> _navigateToDefaultSmsScreen() async {
    // الانتقال إلى شاشة تعيين التطبيق الافتراضي والانتظار للنتيجة
    final becameDefault = await context.push<bool>('/messaging/default-sms-setup');
    return becameDefault == true;
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);

    if (_bodyController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.messageEmptyWarning);
      return;
    }

    if (_recipients.isEmpty) {
      setState(() => _errorMessage = l10n.noRecipientsWarning);
      return;
    }

    if (!await _isDefaultSmsApp()) {
      final becameDefault = await _navigateToDefaultSmsScreen();
      if (!mounted) return;
      // إذا لم يصبح التطبيق افتراضياً بعد العودة، لا تُرسل
      if (!becameDefault) return;
    }

    // ── تصفية وتحقق الأرقام: تخطى الفارغة والخاطئة فقط (لا إلغاء الكل) ──
    final validator = sl<PhoneValidator>();
    final validRecipients = <SmsRecipient>[];
    final skippedPhones = <String>[];

    for (final r in _recipients) {
      if (r.phoneNumber.isEmpty) {
        SmsLogger.phoneValidation(
          raw: r.contactName,
          normalized: '',
          isValid: false,
          reason: 'empty phone',
        );
        skippedPhones.add(r.contactName);
        continue;
      }
      final v = validator.validate(r.phoneNumber);
      SmsLogger.phoneValidation(
        raw: r.phoneNumber,
        normalized: r.phoneNumber,
        isValid: v.isValid,
        reason: v.errorMessage,
      );
      if (v.isValid) {
        validRecipients.add(r);
      } else {
        skippedPhones.add(r.phoneNumber);
      }
    }

    SmsLogger.bulkSmsStarted(
      totalRecipients: _recipients.length,
      validRecipients: validRecipients.length,
      invalidRecipients: skippedPhones.length,
      messageBody: _bodyController.text.trim(),
    );

    // تنبيه بالأرقام المتخطاة (دون إيقاف الإرسال)
    if (skippedPhones.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.isArabic
                ? 'تم تخطي ${skippedPhones.length} رقم غير صالح'
                : '${skippedPhones.length} invalid number(s) skipped',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (validRecipients.isEmpty) {
      setState(() => _errorMessage = l10n.noRecipientsWarning);
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final repo = sl<SmsRepository>();
    final payload = SmsPayload(
      messageBody: _bodyController.text.trim(),
      recipients: validRecipients,
    );

    final effectiveSourceType = validRecipients.every(
            (r) => r.contactId != null && r.contactId!.isNotEmpty)
        ? 'contact'
        : 'manual';

    final result = await repo.sendBulkSms(
      payload: payload,
      sourceType: effectiveSourceType,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSending = false;
          _errorMessage = failure.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.sendFailed}: ${failure.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (batchResult) {
        SmsLogger.bulkSmsCompleted(
          sent: batchResult.sentSuccessfully,
          failed: batchResult.failedCount,
          failedPhones: batchResult.failedPhoneNumbers,
        );
        if (batchResult.hasFailures) {
          final failed = batchResult.failedPhoneNumbers;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.isArabic
                    ? 'تم الإرسال لـ ${batchResult.sentSuccessfully} وفشل لـ ${failed.length}: ${failed.join(", ")}'
                    : 'Sent: ${batchResult.sentSuccessfully}, Failed ${failed.length}: ${failed.join(", ")}',
              ),
              backgroundColor: batchResult.sentSuccessfully > 0
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.isArabic
                    ? 'تم الإرسال بنجاح لـ ${batchResult.sentSuccessfully} مستلم'
                    : 'Sent successfully to ${batchResult.sentSuccessfully} recipient(s)',
              ),
            ),
          );
        }
        setState(() => _isSending = false);
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.compose),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _send,
            child: _isSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    l10n.send,
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
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '$_estimatedSegments ${l10n.segments}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: List.generate(_recipients.length, (index) {
                  return RecipientChip(
                    recipient: _recipients[index],
                    onRemove: () => _removeRecipient(index),
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
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSending ? null : _send,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
