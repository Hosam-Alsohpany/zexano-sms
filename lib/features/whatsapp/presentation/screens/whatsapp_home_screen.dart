import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/assisted_session.dart';
import 'package:zexano_sms/features/whatsapp/domain/repositories/whatsapp_repository.dart';
import 'package:zexano_sms/features/whatsapp/presentation/widgets/whatsapp_session_tile.dart';

class WhatsAppHomeScreen extends ConsumerStatefulWidget {
  const WhatsAppHomeScreen({super.key});

  @override
  ConsumerState<WhatsAppHomeScreen> createState() => _WhatsAppHomeScreenState();
}

class _WhatsAppHomeScreenState extends ConsumerState<WhatsAppHomeScreen> {
  List<AssistedSession> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = sl<WhatsAppRepository>();
    final result = await repo.listStagingHistory();
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        }
      },
      (sessions) {
        if (mounted) {
          setState(() {
            _sessions = sessions;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.whatsapp),
        actions: [
          IconButton(
            icon: const Icon(Icons.smartphone_outlined),
            tooltip: l10n.selectApp,
            onPressed: () => context.push('/whatsapp/app-selection'),
          ),
        ],
      ),
      body: _buildBody(l10n, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/whatsapp/compose'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: theme.colorScheme.error),
              const SizedBox(height: AppSpacing.lg),
              Text(_errorMessage!, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _loadSessions,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_outlined, size: 80,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.noBatchHistory,
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.tapToCompose,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => context.push('/whatsapp/compose'),
                icon: const Icon(Icons.add),
                label: Text(l10n.compose),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return WhatsAppSessionTile(
            session: session,
            onTap: () => context.push('/whatsapp/batch/${session.sessionId}'),
          );
        },
      ),
    );
  }
}
