import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'shell_screen.dart';
import '../features/contacts/presentation/screens/contacts_home_view.dart';
import '../features/contacts/presentation/screens/contact_detail_screen.dart';
import '../features/contacts/presentation/screens/contact_form_screen.dart';
import '../features/groups/presentation/screens/groups_home_view.dart';
import '../features/groups/presentation/screens/group_detail_screen.dart';
import '../features/groups/presentation/screens/group_form_screen.dart';
import '../features/groups/presentation/screens/add_contacts_to_group_screen.dart';
import '../features/conversations/presentation/screens/conversations_home_screen.dart';
import '../features/conversations/presentation/screens/conversation_detail_screen.dart';
import '../features/history/presentation/screens/history_detail_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/history/presentation/screens/history_stats_screen.dart';
import '../features/history/presentation/screens/history_timeline_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/sms/presentation/screens/sms_compose_screen.dart';
import '../features/sms/presentation/screens/sms_detail_screen.dart';
import '../features/sms/presentation/screens/sms_recipient_selection_screen.dart';
import '../features/sms/presentation/screens/sms_template_form_screen.dart';
import '../features/sms/presentation/screens/sms_templates_screen.dart';
import '../features/sms/presentation/screens/default_sms_setup_screen.dart';
import '../features/whatsapp/presentation/screens/whatsapp_app_selection_screen.dart';
import '../features/whatsapp/presentation/screens/whatsapp_batch_progress_screen.dart';
import '../features/whatsapp/presentation/screens/whatsapp_compose_screen.dart';
import '../features/whatsapp/presentation/screens/whatsapp_home_screen.dart';
import '../features/whatsapp/presentation/screens/whatsapp_recipient_selection_screen.dart';
import '../features/backup/presentation/screens/backup_home_screen.dart';
import '../features/backup/presentation/screens/create_backup_screen.dart';
import '../features/backup/presentation/screens/backup_passphrase_screen.dart';
import '../features/backup/presentation/screens/restore_import_screen.dart';
import '../features/backup/presentation/screens/restore_preview_screen.dart';
import '../features/backup/presentation/screens/restore_result_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/contacts',
    routes: [
      // ═══════════════════════════════════════════════════════════════
      // StatefulShellRoute → يحفظ حالة كل تاب عند التبديل بينها
      // ═══════════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // ── فرع 0: جهات الاتصال ────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                name: 'contacts',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ContactsHomeView(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'contact-new',
                    builder: (context, state) => const ContactFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'contact-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ContactDetailScreen(contactId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'contact-edit',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return ContactFormScreen(contactId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ── فرع 1: المجموعات ───────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                name: 'groups',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: GroupsHomeView(),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'group-new',
                    builder: (context, state) => const GroupFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'group-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return GroupDetailScreen(groupId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: 'group-edit',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return GroupFormScreen(groupId: id);
                        },
                      ),
                      GoRoute(
                        path: 'add-contacts',
                        name: 'group-add-contacts',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return AddContactsToGroupScreen(groupId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ── فرع 2: الرسائل ─────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messaging',
                name: 'messaging',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ConversationsHomeScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'conversation',
                    name: 'conversation-detail',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final peerId = (extra?['peerId'] as String?) ?? '';
                      final displayName = extra?['displayName'] as String?;
                      final targetMessageId =
                          extra?['targetMessageId'] as String?;
                      return ConversationDetailScreen(
                        peerId: peerId,
                        displayName: displayName,
                        targetMessageId: targetMessageId,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'compose',
                    name: 'messaging-compose',
                    builder: (context, state) => const SmsComposeScreen(),
                  ),
                  GoRoute(
                    path: 'recipients',
                    name: 'messaging-recipients',
                    builder: (context, state) =>
                        const SmsRecipientSelectionScreen(),
                  ),
                  GoRoute(
                    path: 'default-sms-setup',
                    name: 'messaging-default-sms-setup',
                    builder: (context, state) =>
                        const DefaultSmsSetupScreen(),
                  ),
                  GoRoute(
                    path: 'templates',
                    name: 'messaging-templates',
                    builder: (context, state) => const SmsTemplatesScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        name: 'messaging-template-new',
                        builder: (context, state) =>
                            const SmsTemplateFormScreen(),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        name: 'messaging-template-edit',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return SmsTemplateFormScreen(templateId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'messaging-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SmsDetailScreen(messageId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── فرع 3: السجل ──────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: 'history',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HistoryScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'timeline',
                    name: 'history-timeline',
                    builder: (context, state) => const HistoryTimelineScreen(),
                  ),
                  GoRoute(
                    path: 'stats',
                    name: 'history-stats',
                    builder: (context, state) => const HistoryStatsScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'history-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return HistoryDetailScreen(entryId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── فرع 4: الإعدادات ──────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════════
      // مسارات مستقلة (بدون شريط التنقل السفلي)
      // ═══════════════════════════════════════════════════════════════
      GoRoute(
        path: '/whatsapp',
        name: 'whatsapp',
        builder: (context, state) => const WhatsAppHomeScreen(),
        routes: [
          GoRoute(
            path: 'compose',
            name: 'whatsapp-compose',
            builder: (context, state) => const WhatsAppComposeScreen(),
          ),
          GoRoute(
            path: 'recipients',
            name: 'whatsapp-recipients',
            builder: (context, state) =>
                const WhatsAppRecipientSelectionScreen(),
          ),
          GoRoute(
            path: 'app-selection',
            name: 'whatsapp-app-selection',
            builder: (context, state) => const WhatsAppAppSelectionScreen(),
          ),
          GoRoute(
            path: 'batch/:sessionId',
            name: 'whatsapp-batch',
            builder: (context, state) {
              final sessionId = state.pathParameters['sessionId']!;
              return WhatsAppBatchProgressScreen(sessionId: sessionId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/backup',
        name: 'backup',
        builder: (context, state) => const BackupHomeScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'backup-create',
            builder: (context, state) => const CreateBackupScreen(),
            routes: [
              GoRoute(
                path: 'passphrase',
                name: 'backup-create-passphrase',
                builder: (context, state) => const BackupPassphraseScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'restore',
            name: 'backup-restore',
            builder: (context, state) => const RestoreImportScreen(),
            routes: [
              GoRoute(
                path: 'preview',
                name: 'backup-restore-preview',
                builder: (context, state) => const RestorePreviewScreen(),
              ),
              GoRoute(
                path: 'result',
                name: 'backup-restore-result',
                builder: (context, state) => const RestoreResultScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
