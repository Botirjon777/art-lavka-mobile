import '../config/constants.dart';
import '../models/ledger_entry.dart';
import '../services/api_client.dart';
import '../utils/error_mapper.dart';
import '../utils/json.dart';
import '../utils/result.dart';

/// Read path for a designer's earnings: the append-only ledger and the balance
/// derived from it. Balance is SUM(amount), computed server-side (SPEC §1).
class EarningsRepository {
  EarningsRepository(this._api);
  final ApiClient _api;

  /// Current available balance (UZS) for the signed-in designer.
  Future<Result<int>> balance() => ErrorMapper.guard(() async {
    final data = await _api.get('/designers/me/balance') as Map;
    return Json.intValue(data['balance']);
  });

  /// A page of ledger entries, newest first.
  Future<Result<List<LedgerEntry>>> ledger({
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) => ErrorMapper.guard(() async {
    final res =
        await _api.get('/designers/me/ledger', query: {'page': page}) as Map;
    return ((res['data'] as List?) ?? const [])
        .map((e) => LedgerEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  });
}
