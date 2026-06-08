import 'package:meta/meta.dart';

import '../utils/json.dart';

/// Why a ledger row exists. The ledger is append-only — balances are SUMS of
/// these rows, never an overwritten field (SPEC §1 "money is sacred").
enum LedgerEntryType {
  royaltyAccrued, // credit: order delivered + return window passed
  payoutDebit, // debit: funds moved out to the designer
  adjustment, // manual correction (credit or debit)
  refundReversal, // debit: order refunded, claw back accrued royalty
}

/// One immutable money event for a designer.
///
/// [amountUzs] is signed: positive = credit (increases balance), negative =
/// debit. Balance = SUM(amountUzs) for a designer.
@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.designerId,
    required this.type,
    required this.amountUzs,
    required this.createdAt,
    this.orderItemId,
    this.payoutId,
    this.memo,
  });

  final String id;
  final String designerId;
  final LedgerEntryType type;

  /// Signed amount in UZS (credit > 0, debit < 0).
  final int amountUzs;

  final String? orderItemId;
  final String? payoutId;
  final String? memo;
  final DateTime createdAt;

  bool get isCredit => amountUzs >= 0;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    id: json['id'] as String,
    designerId: json['designer_id'] as String,
    type: Json.enumByName(
      LedgerEntryType.values,
      json['type'],
      LedgerEntryType.adjustment,
    ),
    amountUzs: Json.intValue(json['amount']),
    orderItemId: Json.stringOrNull(json['order_item_id']),
    payoutId: Json.stringOrNull(json['payout_id']),
    memo: Json.stringOrNull(json['memo']),
    createdAt: Json.date(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'designer_id': designerId,
    'type': type.name,
    'amount': amountUzs,
    'order_item_id': orderItemId,
    'payout_id': payoutId,
    'memo': memo,
    'created_at': createdAt.toIso8601String(),
  };
}
