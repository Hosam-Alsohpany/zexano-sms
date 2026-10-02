import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/custom_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../contacts/data/handlers/device_contacts_handler.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../contacts/presentation/providers/contacts_providers.dart';
import '../../../contacts/presentation/screens/contact_form_screen.dart';
import '../providers/groups_providers.dart';

final allContactsProvider = StreamProvider<List<Contact>>((ref) {
  final repo = ref.watch(contactsRepositoryProvider);
  return repo.watchContacts();
});

final existingMemberIdsProvider =
    FutureProvider.family<Set<String>, String>((ref, groupId) async {
  final repo = ref.watch(groupsRepositoryProvider);
  final result = await repo.listContactsInGroup(groupId);
  return result.fold(
    (failure) => throw failure,
    (contacts) => contacts.map((c) => c.id).toSet(),
  );
});

class AddContactsToGroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AddContactsToGroupScreen({super.key, required this.groupId});

  @override
  ConsumerState<AddContactsToGroupScreen> createState() =>
      _AddContactsToGroupScreenState();
}

class _AddContactsToGroupScreenState
    extends ConsumerState<AddContactsToGroupScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  bool _isSubmitting = false;
  bool _isImporting = false;
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final contactsAsync = ref.watch(allContactsProvider);
    final memberIdsAsync = ref.watch(existingMemberIdsProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.addMembers),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _onAdd,
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
                    l10n.addContacts,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: contactsAsync.when(
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
                PrimaryButton(
                  label: l10n.retry,
                  onPressed: () =>
                      ref.invalidate(allContactsProvider),
                ),
              ],
            ),
          ),
        ),
        data: (contacts) => memberIdsAsync.when(
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
                ],
              ),
            ),
          ),
          data: (existingIds) {
            var available = contacts
                .where((c) => !existingIds.contains(c.id))
                .toList();

            if (_favoritesOnly) {
              available = available.where((c) => c.isFavorite).toList();
            }

            if (_searchController.text.isNotEmpty) {
              final query = _searchController.text.toLowerCase();
              available.retainWhere(
                (c) =>
                    c.fullName.toLowerCase().contains(query) ||
                    c.normalizedPhone.contains(query) ||
                    c.phoneNumber.contains(query),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchContacts,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l10n.allContacts),
                        selected: !_favoritesOnly,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _favoritesOnly = false);
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilterChip(
                        avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                        label: Text(l10n.favorites),
                        selected: _favoritesOnly,
                        onSelected: (selected) {
                          setState(() => _favoritesOnly = selected);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (available.isEmpty)
                  Expanded(
                    child: _searchController.text.isNotEmpty
                        ? Center(
                            child: Text(
                              l10n.noResults,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : _favoritesOnly
                            ? Center(
                                child: Text(
                                  l10n.noFavorites,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.contacts_outlined,
                                      size: 48,
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      l10n.noAvailableContacts,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    FilledButton.tonalIcon(
                                      onPressed: _isImporting ? null : _importFromDevice,
                                      icon: _isImporting
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.download_outlined, size: 18),
                                      label: Text(l10n.importFromDevice),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    TextButton.icon(
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ContactFormScreen(),
                                        ),
                                      ),
                                      icon: const Icon(Icons.person_add_outlined, size: 18),
                                      label: Text(l10n.addContact),
                                    ),
                                  ],
                                ),
                              ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: available.length,
                      itemBuilder: (context, index) {
                        final contact = available[index];
                        final isSelected =
                            _selectedIds.contains(contact.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedIds.add(contact.id);
                              } else {
                                _selectedIds.remove(contact.id);
                              }
                            });
                          },
                          secondary: CustomAvatar(
                            firstName: contact.firstName,
                            lastName: contact.lastName,
                            size: 40,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.fullName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  contact.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 20,
                                  color: contact.isFavorite
                                      ? Colors.amber
                                      : theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.5),
                                ),
                                onPressed: () {
                                  ref
                                      .read(contactsRepositoryProvider)
                                      .toggleFavorite(contact.id);
                                },
                                tooltip: contact.isFavorite
                                    ? l10n.removeFavorite
                                    : l10n.favorite,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            contact.normalizedPhone.isNotEmpty
                                ? contact.normalizedPhone
                                : contact.phoneNumber,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} ${l10n.contacts}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _isSubmitting ? null : () => setState(() => _selectedIds.clear()),
                      child: Text(l10n.clearSelection),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _importFromDevice() async {
    setState(() => _isImporting = true);
    final l10n = AppLocalizations.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    final handler = sl<DeviceContactsHandler>();
    final granted = await handler.requestPermission();
    if (!granted) {
      scaffold.showSnackBar(SnackBar(content: Text(l10n.importFailed)));
      setState(() => _isImporting = false);
      return;
    }

    final deviceContacts = await handler.getDeviceContacts();
    if (deviceContacts.isEmpty) {
      scaffold.showSnackBar(SnackBar(content: Text(l10n.noNewContactsFound)));
      setState(() => _isImporting = false);
      return;
    }

    final repo = ref.read(contactsRepositoryProvider);
    final result = await repo.importDeviceContacts(
      deviceContacts: deviceContacts,
    );

    result.fold(
      (failure) {
        scaffold.showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (importResult) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text(
              importResult.duplicates.isNotEmpty
                  ? '${l10n.contactsImported}: ${importResult.imported.length} | ${l10n.duplicatesFound}: ${importResult.duplicates.length}'
                  : '${l10n.contactsImported}: ${importResult.imported.length}',
            ),
          ),
        );
      },
    );

    ref.invalidate(allContactsProvider);
    setState(() => _isImporting = false);
  }

  Future<void> _onAdd() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context);
    final repo = ref.read(groupsRepositoryProvider);
    final result = await repo.addMultipleContactsToGroup(
      groupId: widget.groupId,
      contactIds: _selectedIds.toList(),
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (membershipResult) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${membershipResult.addedCount} ${l10n.contacts} ${l10n.confirm}',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      },
    );
  }
}


