import 'package:flutter/material.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';
import 'package:zexano_sms/features/whatsapp/domain/entities/whatsapp_app.dart';
import 'package:zexano_sms/features/whatsapp/domain/repositories/whatsapp_repository.dart';

class WhatsAppAppSelectionScreen extends StatefulWidget {
  const WhatsAppAppSelectionScreen({super.key});

  @override
  State<WhatsAppAppSelectionScreen> createState() =>
      _WhatsAppAppSelectionScreenState();
}

class _WhatsAppAppSelectionScreenState
    extends State<WhatsAppAppSelectionScreen> {
  List<WhatsAppApp> _apps = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = sl<WhatsAppRepository>();
    final result = await repo.getInstalledApps();
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        }
      },
      (apps) {
        if (mounted) {
          setState(() {
            _apps = apps;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _selectApp(String packageName, String appName) async {
    final repo = sl<WhatsAppRepository>();
    final result = await repo.setPreferredApp(
      packageName: packageName,
      appName: appName,
    );
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appName)),
          );
          setState(() {
            _apps = _apps.map((a) => a.copyWith(
                  isPreferred: a.packageName == packageName,
                )).toList();
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
        title: Text(l10n.selectApp),
      ),
      body: _buildBody(l10n, theme),
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
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: AppSpacing.lg),
              Text(_errorMessage!, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _loadApps,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n.preferredApp,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._apps.map((app) {
          final isPreferred = app.isPreferred;
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: Icon(
                Icons.chat,
                color: isPreferred
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(app.appName),
              subtitle: Text(app.packageName),
              trailing: isPreferred
                  ? Icon(Icons.check_circle,
                      color: theme.colorScheme.primary)
                  : null,
              enabled: app.isInstalled,
              onTap: app.isInstalled
                  ? () => _selectApp(app.packageName, app.appName)
                  : null,
            ),
          );
        }),
        if (_apps.every((a) => !a.isInstalled))
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Text(
                l10n.noAppInstalled,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
