import 'package:zexano_sms/features/sms/domain/services/message_status_service.dart';

/// Represents a single recipient's delivery status within a batch.
class RecipientDetail {
  final String name;
  final String phone;

  /// Delivery status: 'sent' | 'delivered' | 'failed' | 'queued' | 'sending'
  final String status;

  /// Epoch-seconds of the last status update, if available (e.g. sentAt from DB).
  final int? updatedAt;

  final String? messageId;
  final String? peerId;

  const RecipientDetail({
    required this.name,
    required this.phone,
    required this.status,
    this.updatedAt,
    this.messageId,
    this.peerId,
  });

  bool get isSent => MessageStatusService.isSuccess(status);
  bool get isFailed => MessageStatusService.isFailed(status);
  bool get isReceived => MessageStatusService.isInbound(status);
  bool get isQueued => !isSent && !isFailed && !isReceived;
}
