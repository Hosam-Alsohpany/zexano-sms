import '../entities/contact.dart';
import 'duplicate_result.dart';

class ImportResult {
  final List<Contact> imported;
  final List<DuplicateResult> duplicates;
  final int skippedCount;
  final int totalProcessed;

  const ImportResult({
    required this.imported,
    required this.duplicates,
    required this.skippedCount,
    required this.totalProcessed,
  });

  int get totalImported => imported.length;

  int get totalDuplicates => duplicates.length;

  int get newContacts => totalImported;

  bool get hasDuplicates => duplicates.isNotEmpty;

  bool get hasErrors => skippedCount > 0;

  @override
  String toString() =>
      'ImportResult(imported: $totalImported, duplicates: $totalDuplicates, skipped: $skippedCount, total: $totalProcessed)';
}
