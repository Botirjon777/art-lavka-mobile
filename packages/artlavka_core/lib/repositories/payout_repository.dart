import '../config/constants.dart';
import '../models/payout.dart';
import '../services/api_client.dart';
import '../utils/error_mapper.dart';
import '../utils/result.dart';

/// A designer's withdrawals (BACKEND_NODE.md §5). The server validates the
/// balance ≥ threshold and writes the matching ledger debit atomically; the
/// client never debits directly.
class PayoutRepository {
  PayoutRepository(this._api);
  final ApiClient _api;

  Future<Result<List<Payout>>> myPayouts({
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) => ErrorMapper.guard(() async {
    final res = await _api.get('/payouts/me', query: {'page': page}) as Map;
    return ((res['data'] as List?) ?? const [])
        .map((e) => Payout.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  });

  /// Request a withdrawal of [amountUzs]. Server enforces the minimum threshold
  /// ([AppConstants.minPayoutUzs]) and sufficient balance.
  Future<Result<Payout>> requestPayout({required int amountUzs}) {
    if (amountUzs < AppConstants.minPayoutUzs) {
      return Future.value(
        const Failure(
          'Below payout threshold',
          code: FailureCode.belowPayoutThreshold,
        ),
      );
    }
    return ErrorMapper.guard(() async {
      final data =
          await _api.post('/payouts/request', data: {'amount': amountUzs})
              as Map;
      return Payout.fromJson(data.cast<String, dynamic>());
    });
  }
}
