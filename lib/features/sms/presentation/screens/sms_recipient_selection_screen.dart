import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/core/phone/phone_validator.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/core/utils/sms_logger.dart';
import 'package:zexano_sms/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';
import 'package:zexano_sms/features/sms/domain/models/sms_recipient.dart';

class SmsRecipientSelectionScreen extends ConsumerStatefulWidget {
  const SmsRecipientSelectionScreen({super.key});

  @override
  ConsumerState<SmsRecipientSelectionScreen> createState() =>
      _SmsRecipientSelectionScreenState();
}

class _SmsRecipientSelectionScreenState
    extends ConsumerState<SmsRecipientSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _manualPhonesController = TextEditingController();
  final _contactSearchController = TextEditingController();
  final _selectedContactIds = <String>{};
  final _selectedGroupIds = <String>{};
  bool _contactsFavoritesOnly = false;

  List<ContactItem> _allContacts = [];
  List<GroupItem> _allGroups = [];

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
              .map((c) => ContactItem(
                    id: c.id,
                    name: c.fullName,
                    phone: c.normalizedPhone.isNotEmpty
                        ? c.normalizedPhone
                        : c.phoneNumber,
                    isFavorite: c.isFavorite,
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
              .map((g) => GroupItem(
                    id: g.id,
                    name: g.name,
                    memberCount: g.memberCount,
                  ))
              .toList();
        });
      },
    );
  }

  bool _isConfirming = false;

  Future<void> _confirmSelection() async {
    if (_isConfirming) return;
    final l10n = AppLocalizations.of(context);
    final recipients = <SmsRecipient>[];

    // ── 1. جهات الاتصال المختارة مباشرة ──────────────────────────────
    for (final id in _selectedContactIds) {
      final contact = _allContacts.firstWhere((c) => c.id == id);
      recipients.add(
        SmsRecipient(
          id: id,
          smsMessageId: '',
          contactId: id,
          phoneNumber: contact.phone,
          contactName: contact.name,
        ),
      );
    }

    // ── 2. جلب أعضاء المجموعات المختارة بأرقام هواتفهم الحقيقية ─────
    if (_selectedGroupIds.isNotEmpty) {
      setState(() => _isConfirming = true);
      try {
        final groupsRepo = sl<GroupsRepository>();
        for (final groupId in _selectedGroupIds) {
          final group = _allGroups.firstWhere(
            (g) => g.id == groupId,
            orElse: () => GroupItem(id: groupId, name: groupId, memberCount: 0),
          );

          SmsLogger.groupSelected(
            groupId: groupId,
            groupName: group.name,
            memberCount: group.memberCount,
          );

          final result = await groupsRepo.listContactsInGroup(groupId);
          result.fold(
            (failure) {
              // تجاهل المجموعة إذا فشل تحميل الأعضاء وأظهر رسالة
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.isArabic
                          ? 'فشل تحميل أعضاء المجموعة: ${failure.message}'
                          : 'Failed to load group members: ${failure.message}',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            (contacts) {
              final groupRecipients = <SmsRecipient>[];
              final skipped = <String>[];
              for (final contact in contacts) {
                final phone = contact.normalizedPhone.isNotEmpty
                    ? contact.normalizedPhone
                    : contact.phoneNumber;
                if (phone.isNotEmpty) {
                  groupRecipients.add(
                    SmsRecipient(
                      id: contact.id,
                      smsMessageId: '',
                      contactId: contact.id,
                      phoneNumber: phone,
                      contactName: contact.fullName,
                    ),
                  );
                } else {
                  skipped.add(contact.fullName);
                }
              }
              SmsLogger.recipientsResolved(
                groupName: group.name,
                recipients: groupRecipients,
                skippedPhones: skipped,
              );
              recipients.addAll(groupRecipients);
            },
          );
        }
      } finally {
        if (mounted) setState(() => _isConfirming = false);
      }
    }

    // ── 3. الأرقام المُدخلة يدوياً ────────────────────────────────────
    final manualPhones = _manualPhonesController.text
        .split(RegExp(r'[\n,]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final validator = sl<PhoneValidator>();
    final invalidPhones = <String>[];
    for (final phone in manualPhones) {
      final normalized = sl<NormalizationEngine>().normalize(phone);
      if (normalized.isEmpty) {
        invalidPhones.add(phone);
        continue;
      }
      final v = validator.validate(normalized);
      if (!v.isValid) {
        invalidPhones.add(phone);
        continue;
      }
      recipients.add(
        SmsRecipient(
          id: phone,
          smsMessageId: '',
          phoneNumber: normalized,
          contactName: phone,
        ),
      );
    }

    if (invalidPhones.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.validationInvalidPhone}: ${invalidPhones.join(", ")}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // ── 4. التحقق من وجود مستلمين بأرقام صحيحة ──────────────────────
    if (recipients.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.isArabic
                ? 'لا يوجد أعضاء بأرقام هاتف صالحة في المجموعات المختارة'
                : 'No members with valid phone numbers in selected groups',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    context.pop(recipients);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final hasSelection = _selectedContactIds.isNotEmpty ||
        _selectedGroupIds.isNotEmpty ||
        _manualPhonesController.text.trim().isNotEmpty;

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
          if (_isConfirming)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: hasSelection ? _confirmSelection : null,
              child: Text(
                l10n.done,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasSelection
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.38),
                ),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactsTab(l10n, theme),
          _buildGroupsTab(l10n, theme),
          _buildManualTab(l10n, theme),
        ],
      ),
    );
  }

  Widget _buildContactsTab(AppLocalizations l10n, ThemeData theme) {
    final query = _contactSearchController.text.toLowerCase().trim();
    var filtered = query.isEmpty
        ? _allContacts
        : _allContacts.where((c) {
            final name = c.name.toLowerCase();
            final phone = c.phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
            final q = query.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
            return name.contains(query) || phone.contains(q);
          }).toList();

    if (_contactsFavoritesOnly) {
      filtered = filtered.where((c) => c.isFavorite).toList();
    }

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.allContacts),
                selected: !_contactsFavoritesOnly,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _contactsFavoritesOnly = false);
                  }
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterChip(
                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                label: Text(l10n.favorites),
                selected: _contactsFavoritesOnly,
                onSelected: (selected) {
                  setState(() => _contactsFavoritesOnly = selected);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (filtered.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                _contactsFavoritesOnly
                    ? l10n.noFavorites
                    : (query.isNotEmpty ? l10n.noResults : l10n.noContacts),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final contact = filtered[index];
                final selected = _selectedContactIds.contains(contact.id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedContactIds.add(contact.id);
                      } else {
                        _selectedContactIds.remove(contact.id);
                      }
                    });
                  },
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (contact.isFavorite) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    contact.phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGroupsTab(AppLocalizations l10n, ThemeData theme) {
    if (_allGroups.isEmpty) {
      return Center(
        child: Text(
          l10n.noGroups,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _allGroups.length,
      itemBuilder: (context, index) {
        final group = _allGroups[index];
        final selected = _selectedGroupIds.contains(group.id);
        return CheckboxListTile(
          value: selected,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedGroupIds.add(group.id);
              } else {
                _selectedGroupIds.remove(group.id);
              }
            });
          },
          title: Text(group.name),
          subtitle: Text(
            '${group.memberCount} ${l10n.membersLabel}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          secondary: CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(
              group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
              style: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualTab(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.enterPhonesHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _manualPhonesController,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '771234567\n773456789\n...',
            ),
            keyboardType: TextInputType.multiline,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class ContactItem {
  final String id;
  final String name;
  final String phone;
  final bool isFavorite;

  const ContactItem({
    required this.id,
    required this.name,
    required this.phone,
    this.isFavorite = false,
  });
}

class GroupItem {
  final String id;
  final String name;
  final int memberCount;

  const GroupItem({
    required this.id,
    required this.name,
    required this.memberCount,
  });
}
