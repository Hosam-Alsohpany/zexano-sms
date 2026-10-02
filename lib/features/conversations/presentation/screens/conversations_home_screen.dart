import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/conversations/data/datasources/conversation_local_source.dart';
import 'package:zexano_sms/features/conversations/presentation/providers/conversation_providers.dart';
import 'package:zexano_sms/features/sms/presentation/screens/sms_compose_screen.dart';
import 'package:zexano_sms/shared/selection/selection_state.dart';

class ConversationsHomeScreen extends ConsumerWidget {
  const ConversationsHomeScreen({super.key});

  Future<void> _deleteSelectedConversations(
      BuildContext context, WidgetRef ref, SelectionState<String> selectionState) async {
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

    if (confirmed == true) {
      final selectedList = selectionState.selectedIds.toList();
      final localSource = sl<ConversationLocalSource>();
      await localSource.deleteConversations(selectedList);
      ref.read(conversationSelectionProvider.notifier).clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.entryDeleted)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);
    final selectionState = ref.watch(conversationSelectionProvider);
    final selectionNotifier = ref.read(conversationSelectionProvider.notifier);
    final currentConversations = conversationsAsync.valueOrNull ?? [];

    return PopScope(
      canPop: !selectionState.isSelectionMode,
      onPopInvoked: (didPop) {
        if (!didPop && selectionState.isSelectionMode) {
          selectionNotifier.clear();
        }
      },
      child: Scaffold(
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
                      selectionNotifier
                          .selectAll(currentConversations.map((c) => c.peerId));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.deleteSelected,
                    onPressed: () =>
                        _deleteSelectedConversations(context, ref, selectionState),
                  ),
                ],
              )
            : AppBar(
                title: Text(l10n.messaging),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history_outlined),
                    onPressed: () => context.push('/history'),
                    tooltip: l10n.viewHistory,
                  ),
                ],
              ),
        body: conversationsAsync.when(
          data: (conversations) {
            if (conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.noData, style: theme.textTheme.titleMedium),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final displayName = conv.contactName ??
                    conv.peerId.replaceFirst('sms:', '');
                final isSelected = selectionState.isSelected(conv.peerId);

                String timeStr = '';
                if (conv.lastMessageTimestamp != null) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                      conv.lastMessageTimestamp! * 1000);
                  if (DateTime.now().difference(date).inDays > 0) {
                    timeStr = DateFormat.MMMd().format(date);
                  } else {
                    timeStr = DateFormat.jm().format(date);
                  }
                }

                return ListTile(
                  selected: isSelected,
                  selectedTileColor:
                      theme.colorScheme.primaryContainer.withOpacity(0.3),
                  leading: isSelected
                      ? CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(Icons.check,
                              color: theme.colorScheme.onPrimary),
                        )
                      : CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ),
                  title: Text(
                    displayName,
                    textDirection: displayName.startsWith('+') ||
                            RegExp(r'^\d').hasMatch(displayName)
                        ? TextDirection.ltr
                        : null,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: conv.unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    conv.draft != null
                        ? 'Draft: ${conv.draft}'
                        : (conv.lastMessageBody ?? ''),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: conv.draft != null
                          ? theme.colorScheme.error
                          : (conv.unreadCount > 0
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant),
                      fontWeight: conv.unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: SizedBox(
                    height: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: conv.unreadCount > 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: conv.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        if (conv.unreadCount > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conv.unreadCount}',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  onTap: () {
                    if (selectionState.isSelectionMode) {
                      selectionNotifier.toggle(conv.peerId);
                    } else {
                      context.push(
                        '/messaging/conversation',
                        extra: {
                          'peerId': conv.peerId,
                          'displayName': displayName
                        },
                      );
                    }
                  },
                  onLongPress: () {
                    if (!selectionState.isSelectionMode) {
                      selectionNotifier.enterSelectionMode(conv.peerId);
                    } else {
                      selectionNotifier.toggle(conv.peerId);
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SmsComposeScreen()),
            );
          },
          icon: const Icon(Icons.campaign),
          label: Text(l10n.sendSms),
        ),
      ),
    );
  }
}
