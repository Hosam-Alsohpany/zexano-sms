import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/custom_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/group.dart';
import '../controllers/group_send_notifier.dart';
import '../providers/groups_providers.dart';
import 'groups_home_view.dart';
import '../../../sms/domain/services/sms_capability_service.dart';
import '../../../../core/di/injection_container.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final groupDetailProvider =
    FutureProvider.family<Group, String>((ref, id) async {
  final repo = ref.watch(groupsRepositoryProvider);
  final result = await repo.getGroupById(id);
  return result.fold((failure) => throw failure, (group) => group);
});

final groupMembersProvider =
    FutureProvider.family<List<GroupMemberItem>, String>((ref, groupId) async {
  final repo = ref.watch(groupsRepositoryProvider);
  final result = await repo.listContactsInGroup(groupId);
  return result.fold(
    (failure) => throw failure,
    (contacts) => contacts
        .map((c) => GroupMemberItem(
              id: c.id,
              name: c.fullName,
              phone: c.normalizedPhone.isNotEmpty
                  ? c.normalizedPhone
                  : c.phoneNumber,
            ))
        .toList(),
  );
});

class GroupMemberItem {
  final String id;
  final String name;
  final String phone;

  const GroupMemberItem({
    required this.id,
    required this.name,
    required this.phone,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

/// Invariant #10: GroupDetailScreen is a ConsumerStatefulWidget so that
/// lifecycle events (initState, dispose) are trackable and `mounted` checks
/// are meaningful for all async operations.
class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.groupDetail),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'rename') {
                await _renameGroup(context, widget.groupId, l10n);
              } else if (value == 'delete') {
                await _deleteGroup(context, widget.groupId, l10n);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.renameGroup),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.delete,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.errorOccurred, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: l10n.retry,
                  onPressed: () =>
                      ref.invalidate(groupDetailProvider(widget.groupId)),
                ),
              ],
            ),
          ),
        ),
        data: (group) => _GroupDetailContent(
          group: group,
          groupId: widget.groupId,
          // Invariant: invalidate runs on the mounted ConsumerStatefulWidget ref
          // — not inside a BottomSheet or Dialog callback.
          onMemberAdded: () {
            if (!mounted) return;
            ref.invalidate(groupDetailProvider(widget.groupId));
            ref.invalidate(groupMembersProvider(widget.groupId));
          },
        ),
      ),
    );
  }

  // ── Rename ────────────────────────────────────────────────────────────────

  Future<void> _renameGroup(
    BuildContext context,
    String groupId,
    AppLocalizations l10n,
  ) async {
    final repo = ref.read(groupsRepositoryProvider);
    final current = await repo.getGroupById(groupId);
    if (current.isLeft()) return;
    // mounted check after every await
    if (!mounted) return;

    final currentGroup = current.getOrElse(() => throw StateError('unreachable'));
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameGroupDialog(
        initialName: currentGroup.name,
        l10n: l10n,
      ),
    );

    if (newName == null || newName.isEmpty || newName == currentGroup.name) {
      return;
    }

    final result = await repo.renameGroup(groupId, newName);
    // mounted check after every await
    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (_) {
        ref.invalidate(groupDetailProvider(groupId));
        ref.invalidate(groupMembersProvider(groupId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupUpdated)),
        );
      },
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deleteGroup(
    BuildContext context,
    String groupId,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteGroup),
        content: Text(l10n.deleteGroupConfirmation),
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

    final repo = ref.read(groupsRepositoryProvider);
    final result = await repo.deleteGroup(groupId);
    // mounted check after every await
    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${l10n.errorOccurred}: ${failure.message}')),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupDeleted)),
        );
        ref.invalidate(groupListProvider);
        Navigator.of(context).pop();
      },
    );
  }
}

// ── Rename Group Dialog ───────────────────────────────────────────────────────

class _RenameGroupDialog extends StatefulWidget {
  final String initialName;
  final AppLocalizations l10n;

  const _RenameGroupDialog({
    required this.initialName,
    required this.l10n,
  });

  @override
  State<_RenameGroupDialog> createState() => _RenameGroupDialogState();
}

class _RenameGroupDialogState extends State<_RenameGroupDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.renameGroup),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.l10n.groupName,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.l10n.save),
        ),
      ],
    );
  }
}

// ── Group Detail Content ──────────────────────────────────────────────────────

/// Invariant #10: _GroupDetailContent is now a ConsumerStatefulWidget so that:
///   - `mounted` checks are available after every `await`
///   - `ref.invalidate()` is only called when the widget is mounted
///   - The _sendGroupSms flow is NOT tied to a BottomSheet BuildContext
class _GroupDetailContent extends ConsumerStatefulWidget {
  final Group group;
  final String groupId;
  final VoidCallback onMemberAdded;

  const _GroupDetailContent({
    required this.group,
    required this.groupId,
    required this.onMemberAdded,
  });

  @override
  ConsumerState<_GroupDetailContent> createState() =>
      _GroupDetailContentState();
}

class _GroupDetailContentState extends ConsumerState<_GroupDetailContent> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

    // Invariant #10: observe GroupSendNotifier state — UI reacts to state,
    // NOT to BottomSheet callbacks.
    ref.listen<GroupSendStatus>(groupSendProvider, (_, next) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (next) {
          case GroupSendSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.isArabic
                      ? 'تم إرسال الرسالة للمجموعة'
                      : 'Message sent to group',
                ),
              ),
            );
          case GroupSendNeedsDefaultRole():
            _handleNeedsDefaultRole(context, l10n);
          case GroupSendError(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          default:
            break;
        }
      });
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  widget.group.name.isNotEmpty
                      ? widget.group.name[0].toUpperCase()
                      : 'G',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.group.name,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (widget.group.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.group.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                _memberCountLabel(context, widget.group.memberCount),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final added = await context.push<bool>(
                    '/groups/${widget.groupId}/add-contacts',
                  );
                  // mounted check after navigation await
                  if (added == true && mounted) widget.onMemberAdded();
                },
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: Text(l10n.addMembers),
              ),
              const SizedBox(height: AppSpacing.xs),
              // ── Send SMS to entire group ────────────────────────────────
              // Invariant #10: onPressed opens the compose sheet; the actual
              // send is handled by GroupSendNotifier which is lifecycle-independent.
              FilledButton.icon(
                onPressed: () => _openSendSheet(context, l10n),
                icon: const Icon(Icons.sms, size: 18),
                label: Text(
                  l10n.isArabic ? 'إرسال رسالة للمجموعة' : 'Send SMS to Group',
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.errorOccurred,
                        style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            data: (members) {
              if (members.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      l10n.noMembers,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(groupMembersProvider(widget.groupId));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: CustomAvatar(
                        firstName: member.name,
                        lastName: '',
                        size: 40,
                      ),
                      title: Text(
                        member.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        member.phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: l10n.removeMember,
                        onPressed: () => _confirmRemoveMember(
                            context, widget.groupId, member),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Send flow ─────────────────────────────────────────────────────────────

  /// Invariant #1 + #10:
  /// 1. Check Default SMS Role BEFORE opening the compose sheet.
  /// 2. If not default → show role request → user must accept before sheet opens.
  /// 3. The send operation itself runs in [GroupSendNotifier] which is
  ///    lifecycle-independent: the sheet can close mid-send without crashing.
  Future<void> _openSendSheet(
      BuildContext context, AppLocalizations l10n) async {
    final capService = sl<SmsCapabilityService>();

    // ── Gate check BEFORE any DB row or compose sheet ────────────────────
    final status = await capService.checkCanSend();
    if (!mounted) return;

    switch (status) {
      case SmsCapabilityStatus.permissionDenied:
        // Request SMS permission first.
        final granted = await capService.requestSmsPermission();
        if (!mounted) return;
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.isArabic
                  ? 'يلزم منح إذن إرسال الرسائل'
                  : 'SMS permission is required to send messages'),
            ),
          );
          return;
        }
        // Re-check after grant.
        final reCheck = await capService.checkCanSend();
        if (!mounted) return;
        if (reCheck != SmsCapabilityStatus.canSend) return;

      case SmsCapabilityStatus.needsDefaultRole:
        // Invariant #1: request role BEFORE creating any DB row.
        final accepted = await capService.requestDefaultSmsRole();
        if (!mounted) return;
        if (!accepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.isArabic
                  ? 'يجب تعيين التطبيق كتطبيق الرسائل الافتراضي لإرسال الرسائل'
                  : 'Set Zexano as the default SMS app to send messages'),
            ),
          );
          return; // NO DB rows created
        }

      case SmsCapabilityStatus.notSupported:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.isArabic
                ? 'إرسال الرسائل غير مدعوم على هذا الجهاز'
                : 'SMS sending is not supported on this device'),
          ),
        );
        return;

      case SmsCapabilityStatus.canSend:
        break; // proceed
    }

    // ── Open compose sheet (capability confirmed) ─────────────────────────
    if (!mounted) return;
    await _showComposeSheet(context, l10n);
  }

  /// Opens the compose bottom-sheet.
  ///
  /// Invariant #10: The sheet only collects the message body. Sending is
  /// delegated to [GroupSendNotifier] — the sheet's BuildContext is NEVER used
  /// inside an async send callback. When the sheet closes, the notifier
  /// continues running independently. The parent widget's [ref.listen]
  /// observes the outcome and shows feedback.
  Future<void> _showComposeSheet(
      BuildContext context, AppLocalizations l10n) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Use a dedicated ConsumerWidget for the sheet so it has its own ref
      // that is NOT dependent on _GroupDetailContentState lifetime.
      builder: (sheetCtx) => _ComposeSheet(
        groupId: widget.groupId,
        l10n: l10n,
      ),
    );
  }

  // ── Default SMS Role request (called from GroupSendNotifier listener) ────

  Future<void> _handleNeedsDefaultRole(
      BuildContext context, AppLocalizations l10n) async {
    final capService = sl<SmsCapabilityService>();
    final accepted = await capService.requestDefaultSmsRole();
    // Reset notifier state regardless of outcome
    if (!mounted) return;
    ref.read(groupSendProvider.notifier).reset();

    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.isArabic
              ? 'يجب تعيين التطبيق كتطبيق الرسائل الافتراضي'
              : 'Please set Zexano as default SMS app'),
        ),
      );
    }
  }

  // ── Remove member ─────────────────────────────────────────────────────────

  Future<void> _confirmRemoveMember(
    BuildContext context,
    String gId,
    GroupMemberItem member,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeMember),
        content: Text(
            '${l10n.confirmDeleteGroup}\n\n${member.name} - ${member.phone}'),
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
            child: Text(l10n.removeMember),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(groupsRepositoryProvider);
    final result = await repo.removeContactFromGroup(
      groupId: gId,
      contactId: member.id,
    );
    // mounted check after await — critical invariant
    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorOccurred}: ${failure.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (_) {
        // ref.invalidate is safe here — we checked mounted above
        ref.invalidate(groupMembersProvider(gId));
        ref.invalidate(groupDetailProvider(gId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupUpdated)),
        );
      },
    );
  }

  String _memberCountLabel(BuildContext context, int count) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      if (count == 0) return 'بدون أعضاء';
      if (count == 1) return 'عضو واحد';
      if (count == 2) return 'عضوان';
      return '$count أعضاء';
    }
    if (count == 0) return 'No members';
    if (count == 1) return '1 member';
    return '$count members';
  }
}

// ── Compose Sheet ─────────────────────────────────────────────────────────────

/// Invariant #10: This widget has its own [ConsumerStatefulWidget] lifecycle.
/// It observes [GroupSendNotifier] directly and closes itself when done.
/// The send operation is NOT tied to this widget's BuildContext.
class _ComposeSheet extends ConsumerStatefulWidget {
  final String groupId;
  final AppLocalizations l10n;

  const _ComposeSheet({
    required this.groupId,
    required this.l10n,
  });

  @override
  ConsumerState<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<_ComposeSheet> {
  late final TextEditingController _controller;
  bool _isPopped = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _popSafely() {
    if (!mounted || _isPopped) return;
    _isPopped = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sendStatus = ref.watch(groupSendProvider);
    final isSending = sendStatus is GroupSendLoading;

    // Invariant #10: close the sheet when send completes or fails.
    // The parent widget's ref.listen handles showing snackbars.
    ref.listen<GroupSendStatus>(groupSendProvider, (_, next) {
      if (!mounted) return;
      if (next is GroupSendSuccess ||
          next is GroupSendError ||
          next is GroupSendCancelled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _popSafely();
        });
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sms,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.l10n.isArabic
                      ? 'إرسال رسالة للمجموعة'
                      : 'Send SMS to Group',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                // Close sheet without sending — safe because send is in notifier
                onPressed: isSending
                    ? null // prevent accidental close while sending
                    : _popSafely,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            maxLines: 5,
            minLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.l10n.isArabic
                  ? 'اكتب رسالتك هنا...'
                  : 'Type your message here...',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSending
                  ? null
                  : () {
                      final body = _controller.text.trim();
                      if (body.isEmpty) return;
                      // Invariant #10: delegate to notifier — no BuildContext held
                      ref.read(groupSendProvider.notifier).send(
                            groupId: widget.groupId,
                            messageBody: body,
                          );
                    },
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                isSending
                    ? '...'
                    : widget.l10n.isArabic
                        ? 'إرسال'
                        : 'Send',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
