class BackupConfig {
  final bool includeSms;
  final bool includeWhatsApp;
  final bool includeContacts;
  final bool isEncrypted;
  final String? passphrase;

  const BackupConfig({
    this.includeSms = true,
    this.includeWhatsApp = true,
    this.includeContacts = true,
    this.isEncrypted = false,
    this.passphrase,
  });

  bool get isValid {
    if (isEncrypted && (passphrase == null || passphrase!.isEmpty)) {
      return false;
    }
    if (!includeSms && !includeWhatsApp && !includeContacts) {
      return false;
    }
    return true;
  }

  List<String> get selectedChannels {
    final channels = <String>[];
    if (includeSms) channels.add('sms');
    if (includeWhatsApp) channels.add('whatsapp');
    return channels;
  }

  BackupConfig copyWith({
    bool? includeSms,
    bool? includeWhatsApp,
    bool? includeContacts,
    bool? isEncrypted,
    String? passphrase,
    bool clearPassphrase = false,
  }) {
    return BackupConfig(
      includeSms: includeSms ?? this.includeSms,
      includeWhatsApp: includeWhatsApp ?? this.includeWhatsApp,
      includeContacts: includeContacts ?? this.includeContacts,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      passphrase:
          clearPassphrase ? null : (passphrase ?? this.passphrase),
    );
  }
}
