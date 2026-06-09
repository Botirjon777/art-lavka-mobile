import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';

/// Available balance (UZS) = SUM of the seller's ledger rows.
final balanceProvider = FutureProvider.autoDispose<int>(
  (ref) async =>
      (await ref.watch(earningsRepositoryProvider).balance()).unwrap(),
);

/// Append-only ledger entries, newest first.
final ledgerProvider = FutureProvider.autoDispose<List<LedgerEntry>>(
  (ref) async =>
      (await ref.watch(earningsRepositoryProvider).ledger()).unwrap(),
);

/// The seller's payout requests.
final payoutsProvider = FutureProvider.autoDispose<List<Payout>>(
  (ref) async =>
      (await ref.watch(payoutRepositoryProvider).myPayouts()).unwrap(),
);
