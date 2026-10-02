import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/staged_recipient.dart';

class _ContactItem {
  final String id;
  final String name;
  final String phone;
  const _ContactItem({required this.id, required this.name, required this.phone});
}

class _GroupItem {
  final String id;
  final String name;
  final int memberCount;
  const _GroupItem({required this.id, required this.name, required this.memberCount});
}

class WhatsAppRecipientSelectionScreen extends ConsumerStatefulWidget {
  const WhatsAppRecipientSelectionScreen({super.key});

  @override
  ConsumerState<WhatsAppRecipientSelectionScreen> createState() =>
      _WhatsAppRecipientSelectionScreenState();
}

class _WhatsAppRecipientSelectionScreenState
    extends ConsumerState<WhatsAppRecipientSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _manualPhonesController = TextEditingController();
  final _contactSearchController = TextEditingController();
  final _selectedContactIds = <String>{};
  final _selectedGroupIds = <String>{};

  List<_ContactItem> _allContacts = [];
  List<_GroupItem> _allGroups = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContacts();
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualPhonesController.dispose();
    _contactSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final repo = sl<ContactsRepository>();
    final result = await repo.listContacts();
    result.fold(
      (_) {},
      (contacts) {
        setState(() {
          _allContacts = contacts
              .where((c) => c.normalizedPhone.isNotEmpty)
              .map((c) => _ContactItem(
                    id: c.id,
                    name: c.fullName,
                    phone: c.normalizedPhone,
                  ))
              .toList();
        });
      },
    );
  }

  Future<void> _loadGroups() async {
    final repo = sl<GroupsRepository>();
    final result = await repo.listGroups();
    result.fold(
      (_) {},
      (groups) {
        setState(() {
          _allGroups = groups
              .map((g) => _GroupItem(id: g.id, name: g.name, memberCount: g.memberCount))
              .toList();
        });
      },
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final recipients = <StagedRecipient>[];

    final norm = sl<NormalizationEngine>();

    for (final cid in _selectedContactIds) {
      final contact = _allContacts.firstWhere(
        (c) => c.id == cid,
      );
      recipients.add(StagedRecipient(
        id: cid,
        sessionId: '',
        phoneNumber: contact.phone,
        contactName: contact.name,
        contactId: cid,
        status: 'pending',
      ));
    }

    for (final gid in _selectedGroupIds) {
      final group = _allGroups.firstWhere((g) => g.id == gid);
      recipients.add(StagedRecipient(
        id: gid,
        sessionId: '',
        phoneNumber: '',
        contactName: '${l10n.groupLabel}: ${group.name}',
        status: 'pending',
      ));
    }

    final manualLines = _manualPhonesController.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final line in manualLines) {
      final normalized = norm.normalize(line);
      if (normalized.isNotEmpty) {
        recipients.add(StagedRecipient(
          id: normalized,
          sessionId: '',
          phoneNumber: normalized,
          status: 'pending',
        ));
      }
    }

    context.pop(recipients);
  }

  List<_ContactItem> get _filteredContacts {
    final query = _contactSearchController.text.toLowerCase();
    if (query.isEmpty) return _allContacts;
    return _allContacts
        .where((c) => c.name.toLowerCase().contains(query) || c.phone.contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectRecipients),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.contacts),
            Tab(text: l10n.groups),
            Tab(text: l10n.manualEntry),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text(
              l10n.done,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _contactsTab(l10n, theme),
          _groupsTab(l10n, theme),
          _manualTab(l10n, theme),
        ],
      ),
    );
  }

  Widget _contactsTab(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _contactSearchController,
            decoration: InputDecoration(
              hintText: l10n.searchContacts,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: _filteredContacts.isEmpty
              ? Center(child: Text(l10n.noContacts))
              : ListView.builder(
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, i) {
                    final c = _filteredContacts[i];
                    final selected = _selectedContactIds.contains(c.id);
                    return CheckboxListTile(
                      title: Text(c.name),
                      subtitle: Text(c.phone, textDirection: TextDirection.ltr),
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedContactIds.add(c.id);
                          } else {
                            _selectedContactIds.remove(c.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _groupsTab(AppLocalizations l10n, ThemeData theme) {
    if (_allGroups.isEmpty) {
      return Center(child: Text(l10n.noGroups));
    }

    return ListView.builder(
      itemCount: _allGroups.length,
      itemBuilder: (context, i) {
        final g = _allGroups[i];
        final selected = _selectedGroupIds.contains(g.id);
        return CheckboxListTile(
          title: Text(g.name),
          subtitle: Text('${g.memberCount} ${l10n.membersLabel}'),
          value: selected,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedGroupIds.add(g.id);
              } else {
                _selectedGroupIds.remove(g.id);
              }
            });
          },
        );
      },
    );
  }

  Widget _manualTab(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: TextField(
        controller: _manualPhonesController,
        maxLines: 10,
        decoration: InputDecoration(
          hintText: l10n.enterPhonesHint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        textInputAction: TextInputAction.newline,
      ),
    );
  }
}
