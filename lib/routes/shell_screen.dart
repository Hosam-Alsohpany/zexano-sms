import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection_container.dart';
import '../core/localization/app_localizations.dart';
import '../core/utils/normalization_engine.dart';
import '../features/sms/data/datasources/sms_local_source.dart';
import '../features/sms/data/services/incoming_sms_service.dart';

class AppShell extends StatefulWidget {
  /// يُمرَّر من StatefulShellRoute ويمثّل مكدسات التنقل لكل التابات
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _channel = MethodChannel('com.zexano.sms/sms');
  StreamSubscription<Map<String, dynamic>>? _externalIntentSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfDefaultSmsApp();
      _checkInitialSmsIntent();
    });

    if (sl.isRegistered<IncomingSmsService>()) {
      _externalIntentSub =
          sl<IncomingSmsService>().externalSmsIntents.listen((map) {
        _handleExternalSmsIntent(map);
      });
    }
  }

  @override
  void dispose() {
    _externalIntentSub?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialSmsIntent() async {
    try {
      final initialData =
          await _channel.invokeMapMethod<String, dynamic>('getInitialSmsIntent');
      if (initialData != null && mounted) {
        _handleExternalSmsIntent(initialData);
      }
    } catch (_) {}
  }

  Future<void> _handleExternalSmsIntent(Map<String, dynamic> data) async {
    final rawPhone = (data['phoneNumber'] as String?)?.trim() ?? '';
    if (rawPhone.isEmpty) return;

    final normEngine = sl<NormalizationEngine>();
    final peerId = normEngine.peerIdFor(rawPhone);

    String? displayName;
    try {
      final normalized = normEngine.normalize(rawPhone);
      final contact = await sl<SmsLocalSource>().getContactByPhone(normalized);
      if (contact != null) {
        displayName = '${contact.firstName} ${contact.lastName}'.trim();
      }
    } catch (_) {}

    if (!mounted) return;

    context.push('/messaging/conversation', extra: {
      'peerId': peerId,
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
    });
  }

  Future<void> _checkIfDefaultSmsApp() async {
    try {
      final isDefault = await _channel.invokeMethod<bool>('isDefaultSmsApp') ?? false;
      if (!isDefault && mounted) {
        // إذا لم يكن الافتراضي، ننتقل لشاشة الإعداد (نستخدم pushName لضمان عملها بشكل صحيح مع go_router)
        context.pushNamed('messaging-default-sms-setup');
      }
    } catch (_) {
      // تجاهل الخطأ في حالة عدم توفر الـ platform channel
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      // navigationShell هو IndexedStack يحفظ حالة كل تاب
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            // الضغط على نفس التاب مرتين → يرجع لجذر ذلك التاب
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.contacts_outlined),
            selectedIcon: const Icon(Icons.contacts),
            label: l10n.contactsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.group_outlined),
            selectedIcon: const Icon(Icons.group),
            label: l10n.groupsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.send_outlined),
            selectedIcon: const Icon(Icons.send),
            label: l10n.messagingTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.historyTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}
