import 'dart:convert';
import 'package:crypto/crypto.dart';

class IntegrityService {
  static const int _currentSchemaVersion = 1;

  String computeChecksum(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }

  bool verifyChecksum(String content, String expectedChecksum) {
    return computeChecksum(content) == expectedChecksum;
  }

  String computeFileChecksum(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  bool verifyFileChecksum(List<int> bytes, String expectedChecksum) {
    return computeFileChecksum(bytes) == expectedChecksum;
  }

  bool isSchemaVersionCompatible(int backupVersion) {
    return backupVersion >= 1 && backupVersion <= _currentSchemaVersion;
  }

  int get currentSchemaVersion => _currentSchemaVersion;
}
