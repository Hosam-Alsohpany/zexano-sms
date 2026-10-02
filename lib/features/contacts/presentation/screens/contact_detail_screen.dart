import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/database/local_database.dart' as db;
import '../../../../core/di/injection_container.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/normalization_engine.dart';
import '../../../../shared/widgets/custom_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../providers/contacts_providers.dart';

final contactDetailProvider =
    FutureProvider.family<Contact, String>((ref, id) async {
  final repo = ref.watch(contactsRepositoryProvider);
  final result = await repo.getContactById(id);
  return result.fold((failure) => throw failure, (contact) => contact);
});

final contactTagsProvider =
    FutureProvider.family<List<String>, String>((ref, contactId) async {
  final database = sl<db.AppDatabase>();
  final rows = await (database.select(database.contactTags)
        ..where((t) => t.contactId.equals(contactId)))
      .get();
  if (rows.isEmpty) return [];
  final tagRows = await Future.wait(rows.map((ct) =>
      (database.select(database.tags)
            ..where((t) => t.id.equals(ct.tagId)))
          .getSingleOrNull()));
  return tagRows.whereType<db.Tag>().map((t) => t.name).toList();
});

class ContactDetailScreen extends ConsumerWidget {
  final String contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final contactAsync = ref.watch(contactDetailProvider(contactId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.contactDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editContact,
            onPressed: () => context.push('/contacts/$contactId/edit'),
          ),
        ],
      ),
      body: contactAsync.when(
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
                      ref.invalidate(contactDetailProvider(contactId)),
                ),
              ],
            ),
          ),
        ),
        data: (contact) => _ContactDetailsContent(
          contact: contact,
          onFavoriteToggle: () async {
            final repo = ref.read(contactsRepositoryProvider);
            await repo.toggleFavorite(contact.id);
            ref.invalidate(contactDetailProvider(contactId));
          },
          onDelete: () => _confirmDelete(context, ref, contact, l10n),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Contact contact,
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

    final repo = ref.read(contactsRepositoryProvider);
    final result = await repo.deleteContact(contact.id);
    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorOccurred}: ${failure.message}')),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.contactDeleted)),
        );
        context.pop();
      },
    );
  }
}

class _ContactDetailsContent extends StatelessWidget {
  final Contact contact;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;

  const _ContactDetailsContent({
    required this.contact,
    required this.onFavoriteToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: CustomAvatar(
            firstName: contact.firstName,
            lastName: contact.lastName,
            size: 88,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            contact.fullName,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            contact.normalizedPhone.isNotEmpty
                ? contact.normalizedPhone
                : l10n.noPhoneNumber,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.outlined(
              icon: const Icon(Icons.call_outlined),
              onPressed: contact.phoneNumber.isNotEmpty
                  ? () => _makeCall(contact.phoneNumber)
                  : null,
              tooltip: l10n.isArabic ? 'اتصال' : 'Call',
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton.outlined(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: contact.phoneNumber.isNotEmpty
                  ? () {
                      final phone = contact.normalizedPhone.isNotEmpty
                          ? contact.normalizedPhone
                          : contact.phoneNumber;
                      final peerId =
                          sl<NormalizationEngine>().peerIdFor(phone);
                      context.push('/messaging/conversation', extra: {
                        'peerId': peerId,
                        'displayName': contact.fullName,
                      });
                    }
                  : null,
              tooltip: l10n.isArabic ? 'رسالة' : 'Message',
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton.outlined(
              icon: Icon(
                contact.isFavorite ? Icons.star : Icons.star_border,
                color: contact.isFavorite
                    ? theme.colorScheme.primary
                    : null,
              ),
              onPressed: onFavoriteToggle,
              tooltip: contact.isFavorite
                  ? l10n.removeFavorite
                  : l10n.favorite,
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton.outlined(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: l10n.delete,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: l10n.phoneDisplay,
          value: contact.phoneNumber,
        ),
        if (contact.operatorName.isNotEmpty)
          _InfoRow(
            icon: Icons.signal_cellular_alt_outlined,
            label: l10n.operatorLabel,
            value: contact.operatorName,
          ),
        if (contact.notes.isNotEmpty)
          _InfoRow(
            icon: Icons.notes_outlined,
            label: l10n.notes,
            value: contact.notes,
          ),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: l10n.createdDate,
          value: _formatDate(contact.createdAt, l10n),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        _TagsSection(contactId: contact.id, tagIds: contact.tagIds),
      ],
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDate(int epochSeconds, AppLocalizations l10n) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _TagsSection extends ConsumerWidget {
  final String contactId;
  final Set<String> tagIds;

  const _TagsSection({
    required this.contactId,
    required this.tagIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tagsAsync = ref.watch(contactTagsProvider(contactId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label_outline, size: 20,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.tags,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showManageTagsDialog(context, ref),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l10n.manageTags),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        tagsAsync.when(
          loading: () => const SizedBox(
            height: 20,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => Text(l10n.noTags,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          data: (tagNames) {
            if (tagNames.isEmpty) {
              return Text(l10n.noTags,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant));
            }
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: tagNames
                  .map((name) => Chip(
                        label: Text(name, style: const TextStyle(fontSize: 13)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showManageTagsDialog(
      BuildContext context, WidgetRef ref) async {
    final database = sl<db.AppDatabase>();
    final allTags = await database.select(database.tags).get();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => _TagsDialog(
        contactId: contactId,
        contactTagIds: tagIds,
        allTags: allTags,
      ),
    );

    ref.invalidate(contactDetailProvider(contactId));
    ref.invalidate(contactTagsProvider(contactId));
  }
}

class _TagsDialog extends StatefulWidget {
  final String contactId;
  final Set<String> contactTagIds;
  final List<db.Tag> allTags;

  const _TagsDialog({
    required this.contactId,
    required this.contactTagIds,
    required this.allTags,
  });

  @override
  State<_TagsDialog> createState() => _TagsDialogState();
}

class _TagsDialogState extends State<_TagsDialog> {
  late Set<String> _selectedTagIds;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTagIds = Set.from(widget.contactTagIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.manageTags),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: l10n.enterTagName,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _createTag(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () => _createTag(context),
                  child: Text(l10n.createTag),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.allTags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  l10n.noTags,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.allTags.length,
                  itemBuilder: (ctx, i) {
                    final tag = widget.allTags[i];
                    final isAssigned = _selectedTagIds.contains(tag.id);
                    return CheckboxListTile(
                      dense: true,
                      value: isAssigned,
                      title: Text(tag.name),
                      onChanged: (_) => _toggleTag(tag.id, isAssigned),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _createTag(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final database = sl<db.AppDatabase>();
    final existing = await (database.select(database.tags)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();

    String tagId;
    if (existing != null) {
      tagId = existing.id;
    } else {
      tagId = const Uuid().v4();
      await database.into(database.tags).insert(
        db.TagsCompanion.insert(
          id: tagId,
          tenantId: 'default-tenant',
          name: name,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );
    }

    final repo = sl<ContactsRepository>();
    await repo.assignTagsToContact(
      contactId: widget.contactId,
      tagIds: [tagId],
    );

    _nameController.clear();
    setState(() => _selectedTagIds.add(tagId));
  }

  void _toggleTag(String tagId, bool isCurrentlyAssigned) {
    final repo = sl<ContactsRepository>();
    if (isCurrentlyAssigned) {
      repo.removeTagsFromContact(
        contactId: widget.contactId,
        tagIds: [tagId],
      );
      setState(() => _selectedTagIds.remove(tagId));
    } else {
      repo.assignTagsToContact(
        contactId: widget.contactId,
        tagIds: [tagId],
      );
      setState(() => _selectedTagIds.add(tagId));
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
