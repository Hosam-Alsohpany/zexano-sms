import '../entities/staged_recipient.dart';

class RecipientResolutionResult {
  final List<StagedRecipient> resolved;
  final List<String> unresolvedContactIds;
  final int totalResolved;
  final int totalUnresolved;

  const RecipientResolutionResult({
    required this.resolved,
    this.unresolvedContactIds = const [],
  })  : totalResolved = resolved.length,
        totalUnresolved = unresolvedContactIds.length;

  bool get hasUnresolved => unresolvedContactIds.isNotEmpty;

  @override
  String toString() =>
      'RecipientResolutionResult(resolved: $totalResolved, '
      'unresolved: $totalUnresolved)';
}
