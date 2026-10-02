import 'sms_recipient.dart';


class RecipientResolutionResult {
  final List<SmsRecipient> resolved;
  final List<String> unresolvedContactIds;
  final int totalResolved;
  final int totalUnresolved;

  const RecipientResolutionResult({
    required this.resolved,
    this.unresolvedContactIds = const [],
  })  : totalResolved = resolved.length,
        totalUnresolved = unresolvedContactIds.length;

  bool get hasUnresolved => unresolvedContactIds.isNotEmpty;
}
