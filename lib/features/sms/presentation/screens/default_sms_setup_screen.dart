import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:zexano_sms/config/design_system/app_spacing.dart';
import 'package:zexano_sms/core/localization/app_localizations.dart';

/// شاشة تُعرض عندما يُطلب من المستخدم تعيين Zexano كتطبيق SMS الافتراضي.
/// تُرجع [true] إذا أصبح التطبيق افتراضياً بعد العودة، [false] أو null إذا ألغى.
class DefaultSmsSetupScreen extends StatefulWidget {
  const DefaultSmsSetupScreen({super.key});

  @override
  State<DefaultSmsSetupScreen> createState() => _DefaultSmsSetupScreenState();
}

class _DefaultSmsSetupScreenState extends State<DefaultSmsSetupScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.zexano.sms/sms');

  bool _isChecking = false;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDefault();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// يتم استدعاؤه عند العودة من إعدادات النظام
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDefault();
    }
  }

  Future<void> _checkDefault() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDefaultSmsApp') ?? false;
      if (mounted) {
        setState(() => _isDefault = result);
        if (result) {
          // أصبح تطبيقاً افتراضياً → أرجع true وأغلق الشاشة
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) context.pop(true);
        }
      }
    } catch (_) {}
  }

  Future<void> _requestDefault() async {
    setState(() => _isChecking = true);
    try {
      await _channel.invokeMethod<void>('requestDefaultSmsApp');
      // لا نُرجع هنا - ننتظر didChangeAppLifecycleState
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            children: [
              // ── رأس الصفحة ─────────────────────────────────────────
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  onPressed: () => context.pop(false),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceVariant,
                  ),
                ),
              ),

              const Spacer(),

              // ── أيقونة + عنوان ─────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Transform.scale(
                    scale: 1.3,
                    child: Image.asset(
                      'image/zexano-icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                l10n.isArabic
                    ? 'اجعل Zexano التطبيق الافتراضي للرسائل'
                    : 'Set Zexano as Default SMS App',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                l10n.makeDefaultSmsDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── قائمة الخطوات ──────────────────────────────────────
              _StepCard(
                icon: Icons.shield_outlined,
                label: l10n.isArabic
                    ? 'الإرسال المباشر عبر شبكة الاتصال'
                    : 'Direct SMS via cellular network',
                color: colorScheme.primaryContainer,
                iconColor: colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              _StepCard(
                icon: Icons.group_outlined,
                label: l10n.isArabic
                    ? 'إرسال جماعي للمجموعات المحفوظة'
                    : 'Bulk send to saved groups',
                color: colorScheme.secondaryContainer,
                iconColor: colorScheme.secondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              _StepCard(
                icon: Icons.lock_outlined,
                label: l10n.isArabic
                    ? 'رسائلك تبقى خاصة وآمنة'
                    : 'Your messages stay private and secure',
                color: colorScheme.tertiaryContainer,
                iconColor: colorScheme.tertiary,
              ),

              const Spacer(),

              // ── أزرار الإجراء ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isChecking ? null : _requestDefault,
                  icon: _isChecking
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    l10n.makeDefaultSms,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.pop(false),
                  child: Text(
                    l10n.isArabic
                        ? 'ليس الآن'
                        : 'Not now',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // حالة التحقق
              if (_isDefault)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.isArabic
                            ? 'Zexano هو تطبيق الرسائل الافتراضي الآن'
                            : 'Zexano is now the default SMS app',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  const _StepCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
