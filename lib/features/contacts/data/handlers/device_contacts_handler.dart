import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:uuid/uuid.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';

class DeviceContactsHandler {
  final Uuid _uuid;
  static const _channel = MethodChannel('com.zexano.sms/sms');

  DeviceContactsHandler({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<bool> requestPermission() async {
    // First check if permission is already granted at the OS level.
    // FlutterContacts.requestPermission() can return false on some
    // Android versions even when the permission is already granted,
    // causing a false "permission denied" error.
    final alreadyGranted =
        await _channel.invokeMethod<bool>('hasContactsPermission');
    if (alreadyGranted == true) return true;

    final granted =
        await _channel.invokeMethod<bool>('requestContactsPermission');
    if (granted == true) return true;

    // Fallback: let flutter_contacts try its own request in case
    // the platform channel wasn't set up (e.g. during tests).
    return fc.FlutterContacts.requestPermission();
  }

  Future<List<Contact>> getDeviceContacts() async {
    final rawContacts = await fc.FlutterContacts.getContacts(
      withProperties: true,
    );

    return rawContacts
        .where((c) => c.phones.isNotEmpty)
        .map(mapToAppContact)
        .toList();
  }

  @visibleForTesting
  Contact mapToAppContact(fc.Contact deviceContact) {
    final phone = deviceContact.phones.firstOrNull;

    // Use displayName as the unadulterated ground truth for contact name.
    // Android's internal NameSplitter can arbitrarily classify Arabic particles
    // and emojis into middle_name, causing first/last mappings to lose components.
    String rawDisplayName = deviceContact.displayName.trim();
    if (rawDisplayName.isEmpty) {
      final parts = [
        deviceContact.name.prefix,
        deviceContact.name.first,
        deviceContact.name.middle,
        deviceContact.name.last,
        deviceContact.name.suffix,
      ].map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      rawDisplayName = parts.join(' ');
    }

    return Contact(
      id: _uuid.v4(),
      tenantId: 'default-tenant',
      firstName: rawDisplayName,
      lastName: '',
      phoneNumber: phone?.number ?? '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
