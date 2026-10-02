import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/custom_avatar.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../contacts/presentation/providers/contacts_providers.dart';
import '../../domain/entities/group.dart';
import '../../domain/repositories/groups_repository.dart';
import 'groups_home_view.dart';

class GroupFormScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const GroupFormScreen({super.key, this.groupId});

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedContactIds = {};
  List<Contact> _allContacts = [];
  bool _isLoadingContacts = false;
  bool _isSubmitting = false;
  Group? _existingGroup;

  bool get _isEditing => widget.groupId != null;
  List<Contact> get _selectedContacts =>
      _allContacts.where((c) => _selectedContactIds.contains(c.id)).toList();

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadGroup();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final result = await repo.listContacts();
      if (!mounted) return;
      result.fold(
        (_) {},
        (contacts) => setState(() => _allContacts = contacts),
      );
    } finally {
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _showContactPicker() async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        final tempSelected = Set<String>.from(_selectedContactIds);
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final available = _allContacts
                .where((c) => !_selectedContactIds.contains(c.id) || tempSelected.contains(c.id))
                .toList();
            return AlertDialog(
              title: Text(AppLocalizations.of(context).addMembers),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: available.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context).noAvailableContacts,
                        ),
                      )
                    : ListView.builder(
                        itemCount: available.length,
                        itemBuilder: (context, index) {
                          final contact = available[index];
                          final isChecked = tempSelected.contains(contact.id);
                          final displayPhone = contact.normalizedPhone.isNotEmpty
                              ? contact.normalizedPhone
                              : contact.phoneNumber;
                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  tempSelected.add(contact.id);
                                } else {
                                  tempSelected.remove(contact.id);
                                }
                              });
                            },
                            secondary: CustomAvatar(
                              firstName: contact.firstName,
                              lastName: contact.lastName,
                              size: 40,
                            ),
                            title: Text(contact.fullName),
                            subtitle: Text(displayPhone, textDirection: TextDirection.ltr),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, tempSelected),
                  child: Text(AppLocalizations.of(context).confirm),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedContactIds..clear()..addAll(selected));
    }
  }

  Future<void> _loadGroup() async {
    final repo = sl<GroupsRepository>();
    final result = await repo.getGroupById(widget.groupId!);
    result.fold(
      (_) {},
      (group) {
        _nameController.text = group.name;
        _descriptionController.text = group.description;
        setState(() => _existingGroup = group);
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context);
    final repo = sl<GroupsRepository>();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (_isEditing && _existingGroup != null) {
      final updated = _existingGroup!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      final result = await repo.updateGroup(updated);
      if (!mounted) return;
      result.fold(
        (failure) => _showError(failure.message),
        (_) => _onSuccess(l10n.groupUpdated),
      );
    } else {
      final groupId = DateTime.now().microsecondsSinceEpoch.toString();
      final group = Group(
        id: groupId,
        tenantId: 'default-tenant',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: now,
      );
      final result = await repo.createGroup(group);
      if (!mounted) return;
      result.fold(
        (failure) => _showError(failure.message),
        (_) async {
          if (_selectedContactIds.isNotEmpty) {
            await repo.addMultipleContactsToGroup(
              groupId: groupId,
              contactIds: _selectedContactIds.toList(),
            );
          }
          _onSuccess(l10n.groupSaved);
        },
      );
    }
  }

  void _onSuccess(String message) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    ref.invalidate(groupListProvider);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? l10n.editGroup : l10n.addGroup),
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
                    Icons.group_outlined,
                    size: 44,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.groupName,
                  prefixIcon: const Icon(Icons.group_outlined, size: 20),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? l10n.validationRequired
                        : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.groupDescription,
                  prefixIcon: const Icon(Icons.description_outlined, size: 20),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              if (!_isEditing) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 20,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.addMembers,
                        style: theme.textTheme.titleSmall),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _isLoadingContacts
                          ? null
                          : _showContactPicker,
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('اختيار'),
                    ),
                  ],
                ),
                if (_selectedContacts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _selectedContacts.map((c) {
                      return Chip(
                        avatar: CustomAvatar(
                          firstName: c.firstName,
                          lastName: c.lastName,
                          size: 24,
                        ),
                        label: Text(
                          c.fullName,
                          style: theme.textTheme.labelMedium,
                        ),
                        deleteIcon: Icon(Icons.close, size: 16,
                            color: theme.colorScheme.error),
                        onDeleted: () {
                          setState(() {
                            _selectedContactIds.remove(c.id);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${_selectedContactIds.length} ${l10n.contacts}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
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
                      : Text(_isEditing ? l10n.save : l10n.addGroup),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
