import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';

class SmsTemplateFormScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const SmsTemplateFormScreen({super.key, this.templateId});

  @override
  ConsumerState<SmsTemplateFormScreen> createState() =>
      _SmsTemplateFormScreenState();
}

class _SmsTemplateFormScreenState
    extends ConsumerState<SmsTemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isEditing => widget.templateId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final repo = sl<SmsRepository>();
    final result = await repo.getTemplateById(widget.templateId!);
    result.fold(
      (_) {},
      (template) {
        _titleController.text = template.title;
        _bodyController.text = template.bodyContent;
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context);
    final repo = sl<SmsRepository>();

    if (_isEditing) {
      final result = await repo.updateTemplate(
        widget.templateId!,
        title: _titleController.text.trim(),
        bodyContent: _bodyController.text.trim(),
      );
      if (!mounted) return;
      result.fold(
        (failure) => _showError(failure.message),
        (_) => _onSuccess(l10n.templateSaved),
      );
    } else {
      final result = await repo.createTemplate(
        title: _titleController.text.trim(),
        bodyContent: _bodyController.text.trim(),
      );
      if (!mounted) return;
      result.fold(
        (failure) => _showError(failure.message),
        (_) => _onSuccess(l10n.templateSaved),
      );
    }
  }

  void _onSuccess(String message) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    context.pop();
  }

  void _showError(String message) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editTemplate : l10n.addTemplate),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    l10n.save,
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.templateTitle,
                  prefixIcon:
                      const Icon(Icons.title_outlined, size: 20),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? l10n.validationRequired
                        : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: l10n.templateBody,
                  prefixIcon:
                      const Icon(Icons.text_fields_outlined, size: 20),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? l10n.validationRequired
                        : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? l10n.save : l10n.addTemplate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
