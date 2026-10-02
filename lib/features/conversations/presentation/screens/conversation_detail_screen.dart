import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/database/local_database.dart' as db;
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/conversations/presentation/providers/conversation_providers.dart';
import 'package:zexano_sms/features/sms/data/datasources/sms_local_source.dart';
import 'package:zexano_sms/shared/selection/selection_state.dart';

class ConversationDetailScreen extends ConsumerStatefulWidget {
  final String peerId;
  final String? displayName;
  final String? targetMessageId;

  const ConversationDetailScreen({
    super.key,
    required this.peerId,
    this.displayName,
    this.targetMessageId,
  });

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _targetKey = GlobalKey();

  bool _targetConsumed = false;
  String? _highlightedMessageId;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.targetMessageId == null) {
      _targetConsumed = true;
    }
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _highlightAnimation = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOut,
    );
    _highlightController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationRepositoryProvider).markAsRead(widget.peerId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  void _scrollToTarget(int targetIndex) {
    if (!mounted || !_scrollController.hasClients) return;

    final targetContext = _targetKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      final maxExtent = _scrollController.position.hasContentDimensions
          ? _scrollController.position.maxScrollExtent
          : 10000.0;
      final estimatedOffset = (targetIndex * 80.0).clamp(0.0, maxExtent);
      _scrollController.jumpTo(estimatedOffset);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _targetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    _replyController.clear();
    await ref.read(conversationRepositoryProvider).sendReply(widget.peerId, text);
    await ref.read(conversationRepositoryProvider).clearDraft(widget.peerId);
  }

  void _onWillPop() {
    final text = _replyController.text.trim();
    if (text.isNotEmpty) {
      ref.read(conversationRepositoryProvider).saveDraft(widget.peerId, text);
    } else {
      ref.read(conversationRepositoryProvider).clearDraft(widget.peerId);
    }
  }

  String get _phoneNumber {
    return widget.peerId.replaceFirst('sms:', '').trim();
  }

  Future<void> _makeCall() async {
    final number = _phoneNumber;
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copySingleMessage(String body) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: body));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copy)),
    );
  }

  void _copySelectedMessages(
      List<db.MessageHistoryData> allMessages, SelectionState<String> selectionState) {
    final l10n = AppLocalizations.of(context);
    final selectedMsgs = allMessages
        .where((m) => selectionState.isSelected(m.id))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (selectedMsgs.isEmpty) return;

    final buffer = StringBuffer();
    for (final m in selectedMsgs) {
      final sender =
          m.direction == 'inbound' ? (widget.displayName ?? _phoneNumber) : 'Me';
      final dt = DateTime.fromMillisecondsSinceEpoch(m.timestamp * 1000);
      final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(dt);
      buffer.writeln('[$timeStr] $sender:');
      buffer.writeln(m.messageBody);
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ref.read(messageSelectionProvider(widget.peerId).notifier).clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copySelected)),
    );
  }

  void _copyFullConversation(List<db.MessageHistoryData> allMessages) {
    final l10n = AppLocalizations.of(context);
    if (allMessages.isEmpty) return;
    final sorted = List<db.MessageHistoryData>.from(allMessages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final buffer = StringBuffer();
    for (final m in sorted) {
      final sender =
          m.direction == 'inbound' ? (widget.displayName ?? _phoneNumber) : 'Me';
      final dt = DateTime.fromMillisecondsSinceEpoch(m.timestamp * 1000);
      final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(dt);
      buffer.writeln('[$timeStr] $sender:');
      buffer.writeln(m.messageBody);
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copyConversation)),
    );
  }

  Future<void> _deleteSelectedMessages(
      SelectionState<String> selectionState) async {
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
      final localSource = sl<SmsLocalSource>();
      await localSource.deleteHistoryRowsByIds(selectedList);
      if (!mounted) return;
      ref.read(messageSelectionProvider(widget.peerId).notifier).clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.entryDeleted)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final messagesAsync = ref.watch(conversationDetailProvider(widget.peerId));
    final contactNameAsync =
        ref.watch(contactNameForPeerProvider(widget.peerId));
    final currentMessages = messagesAsync.valueOrNull ?? [];
    if (!_targetConsumed && messagesAsync.hasValue) {
      _targetConsumed = true;
      final msgs = messagesAsync.value ?? [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final targetIndex =
            msgs.indexWhere((m) => m.id == widget.targetMessageId);
        if (targetIndex != -1) {
          setState(() {
            _highlightedMessageId = widget.targetMessageId;
          });
          _highlightController.forward(from: 0.0);
          _scrollToTarget(targetIndex);
        }
      });
    }

    final lastMsgContactName = currentMessages.isNotEmpty &&
            currentMessages.first.contactName.trim().isNotEmpty
        ? currentMessages.first.contactName.trim()
        : null;
    final displayName = contactNameAsync.valueOrNull ??
        widget.displayName ??
        lastMsgContactName ??
        _phoneNumber;

    final selectionState =
        ref.watch(messageSelectionProvider(widget.peerId));
    final selectionNotifier =
        ref.read(messageSelectionProvider(widget.peerId).notifier);

    return PopScope(
      canPop: !selectionState.isSelectionMode,
      onPopInvoked: (didPop) {
        if (!didPop && selectionState.isSelectionMode) {
          selectionNotifier.clear();
        } else if (didPop) {
          _onWillPop();
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
                      selectionNotifier.selectAll(currentMessages.map((m) => m.id));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: l10n.copySelected,
                    onPressed: () =>
                        _copySelectedMessages(currentMessages, selectionState),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.deleteSelected,
                    onPressed: () => _deleteSelectedMessages(selectionState),
                  ),
                ],
              )
            : AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      textDirection: displayName.startsWith('+') ||
                              RegExp(r'^\d').hasMatch(displayName)
                          ? TextDirection.ltr
                          : null,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _phoneNumber,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.call_outlined),
                    tooltip: 'اتصال',
                    onPressed: _makeCall,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'copy_all') {
                        _copyFullConversation(currentMessages);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'copy_all',
                        child: Row(
                          children: [
                            const Icon(Icons.copy_all, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.copyConversation),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        body: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(child: Text('No messages.'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isOutbound = msg.direction == 'outbound';
                      final isSelected = selectionState.isSelected(msg.id);
                      final isTargetMessage = msg.id == widget.targetMessageId;
                      final isHighlighted = msg.id == _highlightedMessageId;
                      final date = DateTime.fromMillisecondsSinceEpoch(
                          msg.timestamp * 1000);
                      final timeStr = DateFormat.jm().format(date);

                      IconData? statusIcon;
                      if (isOutbound) {
                        switch (msg.executionStatus) {
                          case 'queued':
                            statusIcon = Icons.access_time;
                            break;
                          case 'sent':
                            statusIcon = Icons.check;
                            break;
                          case 'delivered':
                            statusIcon = Icons.done_all;
                            break;
                          case 'failed':
                            statusIcon = Icons.error_outline;
                            break;
                        }
                      }

                      return GestureDetector(
                        key: isTargetMessage ? _targetKey : null,
                        onLongPress: () {
                          if (!selectionState.isSelectionMode) {
                            selectionNotifier.enterSelectionMode(msg.id);
                          } else {
                            selectionNotifier.toggle(msg.id);
                          }
                        },
                        onTap: () {
                          if (selectionState.isSelectionMode) {
                            selectionNotifier.toggle(msg.id);
                          } else {
                            _showSingleMessageMenu(context, msg);
                          }
                        },
                        child: Align(
                          alignment: isOutbound
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: _highlightAnimation,
                            builder: (context, child) {
                              final glowProgress = isHighlighted
                                  ? (1.0 - _highlightAnimation.value)
                                      .clamp(0.0, 1.0)
                                  : 0.0;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primaryContainer
                                      : (isOutbound
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.surfaceVariant),
                                  borderRadius:
                                      BorderRadius.circular(16).copyWith(
                                    bottomRight: isOutbound
                                        ? const Radius.circular(0)
                                        : null,
                                    bottomLeft: !isOutbound
                                        ? const Radius.circular(0)
                                        : null,
                                  ),
                                  border: isSelected
                                      ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 2)
                                      : (glowProgress > 0
                                          ? Border.all(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(glowProgress),
                                              width: 2.5)
                                          : null),
                                  boxShadow: glowProgress > 0
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withOpacity(
                                                    glowProgress * 0.5),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: child,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.messageBody,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : (isOutbound
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme
                                                .onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      timeStr,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: isSelected
                                            ? theme.colorScheme
                                                .onPrimaryContainer
                                                .withOpacity(0.7)
                                            : (isOutbound
                                                ? theme.colorScheme.onPrimary
                                                    .withOpacity(0.7)
                                                : theme.colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.7)),
                                      ),
                                    ),
                                    if (isOutbound && statusIcon != null) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        statusIcon,
                                        size: 12,
                                        color: msg.executionStatus == 'failed'
                                            ? theme.colorScheme.error
                                            : theme.colorScheme.onPrimary
                                                .withOpacity(0.7),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: l10n.typeMessageHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      elevation: 0,
                      onPressed: _sendReply,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSingleMessageMenu(
      BuildContext context, db.MessageHistoryData msg) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text(l10n.copy),
            onTap: () {
              Navigator.pop(ctx);
              _copySingleMessage(msg.messageBody);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.delete),
            onTap: () async {
              Navigator.pop(ctx);
              final localSource = sl<SmsLocalSource>();
              await localSource.deleteHistoryRowsByIds([msg.id]);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.entryDeleted)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
