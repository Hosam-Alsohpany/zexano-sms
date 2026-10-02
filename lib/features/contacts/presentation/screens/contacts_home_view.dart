import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/handlers/csv_vcf_contacts_handler.dart';
import '../../domain/entities/contact.dart';
import '../../domain/value_objects/contact_filter.dart';
import '../controllers/contact_list_notifier.dart';
import '../providers/contacts_providers.dart';
import '../widgets/contact_list_tile.dart';
import '../../../../shared/selection/selection_state.dart';

final contactListProvider = StateNotifierProvider<ContactListNotifier,
    AsyncValue<List<Contact>>>(
  (ref) => ContactListNotifier(ref),
);

class ContactsHomeView extends ConsumerStatefulWidget {
  const ContactsHomeView({super.key});

  @override
  ConsumerState<ContactsHomeView> createState() => _ContactsHomeViewState();
}

class _ContactsHomeViewState extends ConsumerState<ContactsHomeView>
    with SingleTickerProviderStateMixin {
  bool _showSearch = false;
  final _searchController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final isFavorites = _tabController.index == 1;
        ref.read(contactListProvider.notifier).setFavoritesOnly(isFavorites);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
    ref.read(contactListProvider.notifier).loadContacts(query: value);
  }

  Future<void> _deleteSelectedContacts(
      BuildContext context, SelectionState<String> selectionState) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSelected),
        content: Text(l10n.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final selectedList = selectionState.selectedIds.toList();
      final repo = ref.read(contactsRepositoryProvider);
      for (final id in selectedList) {
        await repo.deleteContact(id);
      }
      if (!mounted) return;
      ref.read(contactSelectionProvider.notifier).clear();
      ref.read(contactListProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactDeleted)),
      );
    }
  }

  Future<void> _exportSelectedContacts(
      BuildContext context, SelectionState<String> selectionState) async {
    final l10n = AppLocalizations.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    final contacts = ref.read(contactListProvider).valueOrNull ?? [];
    final selectedContacts = contacts
        .where((c) => selectionState.isSelected(c.id))
        .toList();

    if (selectedContacts.isEmpty) return;

    FocusScope.of(context).unfocus();
    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chooseExportFormat),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.contact_page_outlined),
                title: Text(l10n.exportAsVcf),
                onTap: () => Navigator.pop(ctx, 'vcf'),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(l10n.exportAsCsv),
                onTap: () => Navigator.pop(ctx, 'csv'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (format == null || !mounted) return;

    final handler = sl<CsvVcfContactsHandler>();
    final exportResult = await handler.exportContactsToFile(
      contacts: selectedContacts,
      format: format,
    );

    if (!mounted) return;
    if (exportResult.isSuccess) {
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.exportSuccess)),
      );
      ref.read(contactSelectionProvider.notifier).clear();
    } else if (exportResult.isCancelled) {
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.exportCancelled)),
      );
    } else {
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.exportFailed}${exportResult.errorMessage != null ? ': ${exportResult.errorMessage}' : ''}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showExportDialog() async {
    final l10n = AppLocalizations.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    String selectedScope = _tabController.index == 1 ? 'favorites' : 'all';
    String selectedFormat = 'vcf';

    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.exportContacts),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chooseExportScope,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RadioListTile<String>(
                      dense: true,
                      title: Text(l10n.exportScopeAll),
                      value: 'all',
                      groupValue: selectedScope,
                      onChanged: (val) =>
                          setDialogState(() => selectedScope = val!),
                    ),
                    RadioListTile<String>(
                      dense: true,
                      title: Text(l10n.exportScopeFavorites),
                      value: 'favorites',
                      groupValue: selectedScope,
                      onChanged: (val) =>
                          setDialogState(() => selectedScope = val!),
                    ),
                    const Divider(),
                    Text(
                      l10n.chooseExportFormat,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    RadioListTile<String>(
                      dense: true,
                      title: Text(l10n.exportAsVcf),
                      value: 'vcf',
                      groupValue: selectedFormat,
                      onChanged: (val) =>
                          setDialogState(() => selectedFormat = val!),
                    ),
                    RadioListTile<String>(
                      dense: true,
                      title: Text(l10n.exportAsCsv),
                      value: 'csv',
                      groupValue: selectedFormat,
                      onChanged: (val) =>
                          setDialogState(() => selectedFormat = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.export),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final repo = ref.read(contactsRepositoryProvider);
    final filter = selectedScope == 'favorites'
        ? const ContactFilter(favoritesOnly: true)
        : null;
    final contactsResult = await repo.listContacts(filter: filter);
    final contactsToExport = contactsResult.fold(
      (failure) => <Contact>[],
      (list) => list,
    );

    if (contactsToExport.isEmpty) {
      if (!mounted) return;
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            selectedScope == 'favorites'
                ? l10n.noFavorites
                : l10n.noContacts,
          ),
        ),
      );
      return;
    }

    final handler = sl<CsvVcfContactsHandler>();
    final exportResult = await handler.exportContactsToFile(
      contacts: contactsToExport,
      format: selectedFormat,
    );

    if (!mounted) return;
    if (exportResult.isSuccess) {
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.exportSuccess)),
      );
    } else if (exportResult.isCancelled) {
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.exportCancelled)),
      );
    } else {
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.exportFailed}${exportResult.errorMessage != null ? ': ${exportResult.errorMessage}' : ''}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showImportSourceDialog() async {
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final source = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importContacts),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone_android_outlined),
                title: Text(l10n.importFromDevice),
                subtitle: Text(l10n.importFromDeviceSubtitle),
                onTap: () => Navigator.pop(ctx, 'device'),
              ),
              ListTile(
                leading: const Icon(Icons.file_present_outlined),
                title: Text(l10n.importFromFile),
                subtitle: Text(l10n.importFromFileSubtitle),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_outlined),
                title: Text(l10n.addContact),
                subtitle: Text(l10n.addContactSubtitle),
                onTap: () => Navigator.pop(ctx, 'manual'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (source == 'device') {
      await _importFromDevice();
    } else if (source == 'file') {
      await _importFromFile();
    } else if (source == 'manual') {
      context.push('/contacts/new');
    }
  }

  Future<void> _importFromDevice() async {
    final l10n = AppLocalizations.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    scaffold.showSnackBar(SnackBar(content: Text(l10n.importInProgress)));

    final notifier = ref.read(contactListProvider.notifier);
    final result = await notifier.importFromDevice();

    if (!mounted) return;
    scaffold.hideCurrentSnackBar();

    switch (result.status) {
      case ImportStatus.permissionDenied:
        scaffold.showSnackBar(
          SnackBar(
            content: Text(l10n.permissionDenied),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      case ImportStatus.noContacts:
        scaffold.showSnackBar(
          SnackBar(content: Text(l10n.noNewContactsFound)),
        );
      case ImportStatus.success:
        scaffold.showSnackBar(
          SnackBar(
            content: Text(
              result.duplicates > 0
                  ? '${l10n.contactsImported}: ${result.imported} | ${l10n.duplicatesFound}: ${result.duplicates}'
                  : '${l10n.contactsImported}: ${result.imported}',
            ),
          ),
        );
      case ImportStatus.onlyDuplicates:
        scaffold.showSnackBar(
          SnackBar(
            content: Text('${l10n.duplicatesFound}: ${result.duplicates}'),
          ),
        );
      case ImportStatus.noFileSelected:
        break;
    }
  }

  Future<void> _importFromFile() async {
    final l10n = AppLocalizations.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    scaffold.showSnackBar(SnackBar(content: Text(l10n.importInProgress)));

    final notifier = ref.read(contactListProvider.notifier);
    final result = await notifier.importFromFile();

    if (!mounted) return;
    scaffold.hideCurrentSnackBar();

    switch (result.status) {
      case ImportStatus.noFileSelected:
        return;
      case ImportStatus.noContacts:
        scaffold.showSnackBar(
          SnackBar(content: Text(l10n.noNewContactsFound)),
        );
      case ImportStatus.success:
        scaffold.showSnackBar(
          SnackBar(
            content: Text(
              result.duplicates > 0
                  ? '${l10n.contactsImported}: ${result.imported} | ${l10n.duplicatesFound}: ${result.duplicates}'
                  : '${l10n.contactsImported}: ${result.imported}',
            ),
          ),
        );
      case ImportStatus.onlyDuplicates:
        scaffold.showSnackBar(
          SnackBar(
            content: Text('${l10n.duplicatesFound}: ${result.duplicates}'),
          ),
        );
      case ImportStatus.permissionDenied:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final contactsAsync = ref.watch(contactListProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectionState = ref.watch(contactSelectionProvider);
    final selectionNotifier = ref.read(contactSelectionProvider.notifier);

    return Scaffold(
      appBar: selectionState.isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => selectionNotifier.clear(),
              ),
              title: Text(l10n.selectedCount(selectionState.selectedCount)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: l10n.selectAll,
                  onPressed: () {
                    final currentContacts = contactsAsync.valueOrNull ?? [];
                    selectionNotifier
                        .selectAll(currentContacts.map((c) => c.id));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file_outlined),
                  tooltip: l10n.exportContacts,
                  onPressed: () =>
                      _exportSelectedContacts(context, selectionState),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.deleteSelected,
                  onPressed: () =>
                      _deleteSelectedContacts(context, selectionState),
                ),
              ],
            )
          : AppBar(
              title: _showSearch
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.searchContacts,
                        border: InputBorder.none,
                        filled: false,
                      ),
                      onChanged: _onSearchChanged,
                    )
                  : Text(l10n.contacts),
              actions: [
                IconButton(
                  icon: Icon(_showSearch ? Icons.close : Icons.search),
                  tooltip: l10n.search,
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchController.clear();
                        _onSearchChanged('');
                      }
                    });
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'import') _showImportSourceDialog();
                    if (value == 'export') _showExportDialog();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          const Icon(Icons.download_outlined, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(l10n.importContacts),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file_outlined, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(l10n.exportContacts),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.allContacts),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 18),
                        const SizedBox(width: AppSpacing.xs),
                        Text(l10n.favorites),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      body: PopScope(
        canPop: !selectionState.isSelectionMode,
        onPopInvoked: (didPop) {
          if (!didPop && selectionState.isSelectionMode) {
            selectionNotifier.clear();
          }
        },
        child: contactsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.errorOccurred,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: l10n.retry,
                    onPressed: () =>
                        ref.read(contactListProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
          data: (contacts) {
            if (_showSearch && searchQuery.isNotEmpty && contacts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.4)),
                      const SizedBox(height: AppSpacing.lg),
                      Text(l10n.noResults,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              );
            }

            if (contacts.isEmpty) {
              if (_tabController.index == 1) {
                return EmptyStateView(
                  icon: Icons.star_border_rounded,
                  title: l10n.noFavorites,
                  subtitle: l10n.noFavoritesSubtitle,
                );
              }
              return EmptyStateView(
                icon: Icons.contacts_outlined,
                title: l10n.noContacts,
                subtitle: l10n.addContactSubtitle,
                actionLabel: l10n.importFromDevice,
                onAction: _showImportSourceDialog,
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(contactListProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final isSelected = selectionState.isSelected(contact.id);
                  return ContactListTile(
                    contact: contact,
                    isSelected: isSelected,
                    isSelectionMode: selectionState.isSelectionMode,
                    onTap: () {
                      if (selectionState.isSelectionMode) {
                        selectionNotifier.toggle(contact.id);
                      } else {
                        context.push('/contacts/${contact.id}');
                      }
                    },
                    onLongPress: () {
                      if (!selectionState.isSelectionMode) {
                        selectionNotifier.enterSelectionMode(contact.id);
                      } else {
                        selectionNotifier.toggle(contact.id);
                      }
                    },
                    onFavoriteToggle: () => ref
                        .read(contactListProvider.notifier)
                        .toggleFavorite(contact.id),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/contacts/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
