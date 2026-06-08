import '../models/designer_profile.dart';
import '../services/api_client.dart';
import '../utils/error_mapper.dart';
import '../utils/result.dart';

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
