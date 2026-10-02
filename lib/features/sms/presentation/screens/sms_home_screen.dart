import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/sms/domain/entities/sms_message.dart';
import 'package:zexano_sms/features/sms/presentation/controllers/sms_list_notifier.dart';
import 'package:zexano_sms/features/sms/presentation/widgets/sms_list_tile.dart';
import 'package:zexano_sms/shared/widgets/empty_state_view.dart';
import 'package:zexano_sms/shared/widgets/primary_button.dart';
import 'package:zexano_sms/features/sms/presentation/screens/sms_templates_screen.dart';
import 'package:zexano_sms/features/sms/presentation/screens/sms_compose_screen.dart';
import 'package:zexano_sms/features/sms/presentation/screens/sms_detail_screen.dart';
import 'package:zexano_sms/features/whatsapp/presentation/screens/whatsapp_home_screen.dart';

final smsListProvider = StateNotifierProvider<SmsListNotifier,
    AsyncValue<List<SmsMessage>>>(
  (ref) => SmsListNotifier(ref),
);

class SmsHomeScreen extends ConsumerStatefulWidget {
  const SmsHomeScreen({super.key});

  @override
  ConsumerState<SmsHomeScreen> createState() => _SmsHomeScreenState();
}

class _SmsHomeScreenState extends ConsumerState<SmsHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(smsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.smsMessages),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: l10n.templates,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SmsTemplatesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            tooltip: l10n.whatsapp,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhatsAppHomeScreen())),
          ),
        ],
      ),
      body: messagesAsync.when(
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
                      ref.read(smsListProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
        data: (messages) {
          if (messages.isEmpty) {
            return EmptyStateView(
              icon: Icons.send_outlined,
              title: l10n.noMessages,
              subtitle: l10n.tapToCompose,
              actionLabel: l10n.compose,
              onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SmsComposeScreen())),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(smsListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return SmsListTile(
                  message: message,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SmsDetailScreen(messageId: message.id))),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SmsComposeScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
