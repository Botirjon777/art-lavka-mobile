import '../models/designer_profile.dart';
import '../services/api_client.dart';
import '../utils/error_mapper.dart';
import '../utils/json.dart';
import '../utils/result.dart';

/// A designer's portfolio + earnings summary (Studio dashboard).
class DesignerStats {
  const DesignerStats({
    required this.designs,
    required this.listings,
    required this.sales,
    required this.balanceUzs,
  });

  final int designs;
  final int listings;
  final int sales;
  final int balanceUzs;

  factory DesignerStats.fromJson(Map<String, dynamic> json) => DesignerStats(
    designs: Json.intValue(json['designs']),
    listings: Json.intValue(json['listings']),
    sales: Json.intValue(json['sales']),
    balanceUzs: Json.intValue(json['balance_uzs']),
  );
}

/// Seller onboarding + profile (SPEC §9). The server scopes everything to the
/// authenticated user; the Studio dashboard gate reads [DesignerProfile.kycStatus].
class DesignerRepository {
  DesignerRepository(this._api);
  final ApiClient _api;

  /// The caller's designer profile, or `null` if they haven't onboarded yet.
  Future<Result<DesignerProfile?>> myProfile() => ErrorMapper.guard(() async {
    final data = await _api.get('/designers/me/profile');
    if (data == null) return null;
    return DesignerProfile.fromJson((data as Map).cast<String, dynamic>());
  });

  /// The caller's portfolio + earnings stats.
  Future<Result<DesignerStats>> stats() => ErrorMapper.guard(() async {
    final data = await _api.get('/designers/me/stats') as Map;
    return DesignerStats.fromJson(data.cast<String, dynamic>());
  });

  /// Submit KYC + accepted contract + typed signature → status `pending`.
  Future<Result<DesignerProfile>> onboard({
    required String displayName,
    required String legalName,
    required PayoutMethod payoutMethod,
    required String contractVersion,
    required String regulationsHash,
    required String signatureName,
    String? idNumber,
  }) => ErrorMapper.guard(() async {
    final data =
        await _api.post(
              '/designers/onboard',
              data: {
                'displayName': displayName,
                'legalName': legalName,
                'idNumber': ?idNumber,
                'payoutMethod': payoutMethod.name,
                'contractVersion': contractVersion,
                'regulationsHash': regulationsHash,
                'signatureName': signatureName,
              },
            )
            as Map;
    return DesignerProfile.fromJson(data.cast<String, dynamic>());
  });
}
