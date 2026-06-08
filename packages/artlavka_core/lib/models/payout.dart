import 'package:meta/meta.dart';

import '../utils/json.dart';
import 'designer_profile.dart';

/// Lifecycle of a withdrawal request.
enum PayoutStatus { requested, processing, paid, failed }

/// A designer's withdrawal. Creating one writes a matching debit to the
/// ledger (SPEC §5 `request-payout`).
@immutable
class Payout {
  const Payout({
    required this.id,
    required this.designerId,
    required this.amountUzs,
    required this.status,
    required this.method,
    required this.requestedAt,
    this.processedAt,
    this.failureReason,
  });

  final String id;
  final String designerId;
  final int amountUzs;
  final PayoutStatus status;
  final PayoutMethod method;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? failureReason;

  factory Payout.fromJson(Map<String, dynamic> json) => Payout(
    id: json['id'] as String,
    designerId: json['designer_id'] as String,
    amountUzs: Json.intValue(json['amount']),
    status: Json.enumByName(
      PayoutStatus.values,
      json['status'],
      PayoutStatus.requested,
    ),
    method: Json.enumByName(
      PayoutMethod.values,
      json['method'],
      PayoutMethod.card,
    ),
    requestedAt: Json.date(json['requested_at']),
    processedAt: Json.dateOrNull(json['processed_at']),
    failureReason: Json.stringOrNull(json['failure_reason']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'designer_id': designerId,
    'amount': amountUzs,
    'status': status.name,
    'method': method.name,
    'requested_at': requestedAt.toIso8601String(),
    'processed_at': processedAt?.toIso8601String(),
    'failure_reason': failureReason,
  };
}
