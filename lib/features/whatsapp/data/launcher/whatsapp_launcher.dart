import '../../domain/entities/whatsapp_app.dart';
import '../../domain/models/launch_result.dart';

abstract class WhatsAppLauncher {
  Future<List<WhatsAppApp>> detectInstalledApps();
  Future<LaunchResult> launch({
    required String recipientId,
    required String phoneNumber,
    required String messageBody,
    required String packageName,
  });
  bool get canDetectApps;
  bool get canLaunch;
}

class NoopWhatsAppLauncher extends WhatsAppLauncher {
  @override
  bool get canDetectApps => true;

  @override
  bool get canLaunch => true;

  @override
  Future<List<WhatsAppApp>> detectInstalledApps() async {
    return [
      const WhatsAppApp(
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        isInstalled: true,
        isPreferred: false,
      ),
      const WhatsAppApp(
        packageName: 'com.whatsapp.w4b',
        appName: 'WhatsApp Business',
        isInstalled: true,
        isPreferred: false,
      ),
    ];
  }

  @override
  Future<LaunchResult> launch({
    required String recipientId,
    required String phoneNumber,
    required String messageBody,
    required String packageName,
  }) async {
    return LaunchResult(
      recipientId: recipientId,
      success: true,
    );
  }
}

class CapabilityAwareWhatsAppLauncher extends WhatsAppLauncher {
  final bool _canDetect;
  final bool _canLaunch;
  final String? _capabilityError;

  CapabilityAwareWhatsAppLauncher({
    bool canDetect = true,
    bool canLaunch = true,
    String? capabilityError,
  })  : _canDetect = canDetect,
        _canLaunch = canLaunch,
        _capabilityError = capabilityError;

  @override
  bool get canDetectApps => _canDetect;

  @override
  bool get canLaunch => _canLaunch;

  @override
  Future<List<WhatsAppApp>> detectInstalledApps() async {
    if (!_canDetect) {
      return [];
    }
    return [
      const WhatsAppApp(
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        isInstalled: true,
        isPreferred: false,
      ),
    ];
  }

  @override
  Future<LaunchResult> launch({
    required String recipientId,
    required String phoneNumber,
    required String messageBody,
    required String packageName,
  }) async {
    if (!_canLaunch) {
      return LaunchResult(
        recipientId: recipientId,
        success: false,
        failureReason:
            _capabilityError ?? 'WhatsApp launch capability not available',
      );
    }
    return LaunchResult(
      recipientId: recipientId,
      success: true,
    );
  }
}
