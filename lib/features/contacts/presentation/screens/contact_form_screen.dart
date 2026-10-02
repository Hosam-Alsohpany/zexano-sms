import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/phone/phone_validator.dart';
import '../../domain/entities/contact.dart';
import '../providers/contacts_providers.dart';
import '../screens/contacts_home_view.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  final String? contactId;

  const ContactFormScreen({super.key, this.contactId});

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneValidator = PhoneValidator();
  bool _isSubmitting = false;
  Contact? _existingContact;

  String _selectedCountryCode = '+967';

  bool get _isEditing => widget.contactId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadContact();
  }

  // Issue #3 & #4: use GetContactById use case via Riverpod — no more sl<>
  Future<void> _loadContact() async {
    final useCase = ref.read(getContactByIdUseCaseProvider);
    final result = await useCase(widget.contactId!);
    result.fold(
      (_) {},
      (contact) {
        _firstNameController.text = contact.firstName;
        _lastNameController.text = contact.lastName;
        _phoneController.text = _stripCountryCode(contact.phoneNumber);
        _notesController.text = contact.notes;
        final cc = _detectCountryCode(contact.phoneNumber);
        if (cc != null) {
          _selectedCountryCode = cc;
        }
        setState(() => _existingContact = contact);
      },
    );
  }

  String _stripCountryCode(String phone) {
    for (final entry in _countryCodes) {
      if (phone.startsWith(entry.$1)) {
        return phone.substring(entry.$1.length);
      }
    }
    return phone;
  }

  String? _detectCountryCode(String phone) {
    for (final entry in _countryCodes) {
      if (phone.startsWith(entry.$1)) {
        return entry.$1;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Issue #3 & #4: use CreateContact / UpdateContact use cases via Riverpod
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';

    if (_isEditing && _existingContact != null) {
      final updated = _existingContact!.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: fullPhone,
        notes: _notesController.text.trim(),
      );
      final useCase = ref.read(updateContactUseCaseProvider);
      final result = await useCase(updated);
      if (!mounted) return;
      result.fold(
        (failure) => _showError(failure.message),
        (_) => _onSuccess(l10n.contactUpdated),
      );
    } else {
      final contact = Contact(
        id: const Uuid().v4(),
        tenantId: 'default-tenant',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: fullPhone,
        notes: _notesController.text.trim(),
        createdAt: now,
      );
      final useCase = ref.read(createContactUseCaseProvider);
      final result = await useCase(contact);
      if (!mounted) return;
      result.fold(
        (failure) => _showError(failure.message),
        (_) => _onSuccess(l10n.contactSaved),
      );
    }
  }

  void _onSuccess(String message) {
    setState(() => _isSubmitting = false);
    // Refresh the contact list so the UI reflects the create/update immediately.
    ref.read(contactListProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pop();
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

  Future<void> _showCountryPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _CountryPickerSheet(
        selectedCode: _selectedCountryCode,
        codes: _countryCodes,
      ),
    );
    if (result != null) {
      setState(() => _selectedCountryCode = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Issue #2: single save entry point — AppBar text button only.
    // The body FilledButton is removed to eliminate the duplicate save action.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? l10n.editContact : l10n.addContact),
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
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_outline,
                    size: 44,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: l10n.firstName,
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? l10n.validationRequired
                              : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: l10n.lastName,
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildPhoneField(l10n, theme),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  prefixIcon: const Icon(Icons.notes_outlined, size: 20),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء حقل رقم الهاتف مع دعم RTL في اللغة العربية
  Widget _buildPhoneField(
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // زر اختيار رمز الدولة
    final countryCodeButton = InkWell(
      onTap: _showCountryPicker,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: isRtl
            ? const EdgeInsetsDirectional.only(start: 4, end: 12)
            : const EdgeInsetsDirectional.only(start: 12, end: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          // في RTL: السهم أولاً ثم الرمز (يبدو طبيعياً من اليمين)
          children: isRtl
              ? [
                  const Icon(Icons.arrow_drop_down, size: 18),
                  Text(
                    _selectedCountryCode,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ]
              : [
                  Text(
                    _selectedCountryCode,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
        ),
      ),
    );

    // Issue #3: normalization engine accessed via Riverpod provider, not sl<>
    return TextFormField(
      controller: _phoneController,
      // إدخال الأرقام دائماً من اليسار لليمين
      textDirection: TextDirection.ltr,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      decoration: InputDecoration(
        labelText: l10n.phoneNumber,
        hintText: '771234567',
        hintTextDirection: TextDirection.ltr,
        // في العربية: رمز الدولة على اليمين (suffix)
        // في الإنجليزية: رمز الدولة على اليسار (prefix)
        prefixIcon: isRtl ? null : countryCodeButton,
        prefixIconConstraints:
            isRtl ? null : const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: isRtl ? countryCodeButton : null,
        suffixIconConstraints:
            isRtl ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
      ),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return l10n.validationRequired;
        }
        final fullPhone = '$_selectedCountryCode${v.trim()}';
        final result = _phoneValidator.validate(fullPhone);
        if (!result.isValid) {
          return l10n.validationInvalidPhone;
        }
        return null;
      },
    );
  }
}

// (رمز الدولة، الاسم بالإنجليزية، الاسم بالعربية، رمز ISO)
const _countryCodes = <(String, String, String, String)>[
  ('+967', 'Yemen', 'اليمن', 'YE'),
  ('+966', 'Saudi Arabia', 'السعودية', 'SA'),
  ('+971', 'United Arab Emirates', 'الإمارات', 'AE'),
  ('+965', 'Kuwait', 'الكويت', 'KW'),
  ('+974', 'Qatar', 'قطر', 'QA'),
  ('+968', 'Oman', 'عُمان', 'OM'),
  ('+973', 'Bahrain', 'البحرين', 'BH'),
  ('+962', 'Jordan', 'الأردن', 'JO'),
  ('+20', 'Egypt', 'مصر', 'EG'),
  ('+963', 'Syria', 'سوريا', 'SY'),
  ('+964', 'Iraq', 'العراق', 'IQ'),
  ('+218', 'Libya', 'ليبيا', 'LY'),
  ('+249', 'Sudan', 'السودان', 'SD'),
  ('+213', 'Algeria', 'الجزائر', 'DZ'),
  ('+212', 'Morocco', 'المغرب', 'MA'),
  ('+216', 'Tunisia', 'تونس', 'TN'),
  ('+1', 'US / Canada', 'أمريكا / كندا', 'US'),
  ('+44', 'United Kingdom', 'المملكة المتحدة', 'GB'),
  ('+49', 'Germany', 'ألمانيا', 'DE'),
  ('+33', 'France', 'فرنسا', 'FR'),
  ('+39', 'Italy', 'إيطاليا', 'IT'),
  ('+34', 'Spain', 'إسبانيا', 'ES'),
  ('+31', 'Netherlands', 'هولندا', 'NL'),
  ('+46', 'Sweden', 'السويد', 'SE'),
  ('+41', 'Switzerland', 'سويسرا', 'CH'),
  ('+61', 'Australia', 'أستراليا', 'AU'),
  ('+91', 'India', 'الهند', 'IN'),
  ('+86', 'China', 'الصين', 'CN'),
  ('+81', 'Japan', 'اليابان', 'JP'),
  ('+82', 'South Korea', 'كوريا الجنوبية', 'KR'),
];

class _CountryPickerSheet extends StatelessWidget {
  final String selectedCode;
  final List<(String, String, String, String)> codes;

  const _CountryPickerSheet({
    required this.selectedCode,
    required this.codes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context).selectCountry,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: codes.length,
            itemBuilder: (ctx, i) {
              final (code, nameEn, nameAr, _) = codes[i];
              final isSelected = code == selectedCode;
              // عرض اسم الدولة بالعربية عند وضع RTL
              final displayName = isRtl ? nameAr : nameEn;
              return ListTile(
                dense: true,
                selected: isSelected,
                title: Row(
                  children: [
                    // رمز الدولة دائماً LTR
                    Text(
                      code,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(displayName)),
                  ],
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, code),
              );
            },
          ),
        ),
      ],
    );
  }
}
