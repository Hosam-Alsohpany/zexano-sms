import '../entities/contact.dart';

class DuplicateResult {
  final Contact existing;
  final Contact incoming;
  final double matchScore;
  final List<String> matchedFields;

  const DuplicateResult({
    required this.existing,
    required this.incoming,
    required this.matchScore,
    required this.matchedFields,
  });

  bool get isExactMatch => matchScore >= 1.0;

  bool get isHighConfidence => matchScore >= 0.8;

  Map<String, dynamic> toMap() {
    return {
      'existing': existing.toMap(),
      'incoming': incoming.toMap(),
      'matchScore': matchScore,
      'matchedFields': matchedFields,
    };
  }

  @override
  String toString() =>
      'DuplicateResult(matchScore: $matchScore, matchedFields: $matchedFields)';
}
