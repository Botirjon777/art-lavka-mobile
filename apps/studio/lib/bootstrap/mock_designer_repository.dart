import 'package:artlavka_core/artlavka_core.dart';

/// In-memory [DesignerRepository] for development/tests (no backend). Onboarding
/// "submits" to a pending profile so the gate can be exercised offline.
class MockDesignerRepository extends DesignerRepository {
  MockDesignerRepository() : super(ApiClient(tokenStore: TokenStore()));

  DesignerProfile? _profile;

  @override
  Future<Result<DesignerProfile?>> myProfile() async => Success(_profile);

  @override
  Future<Result<DesignerStats>> stats() async => const Success(
    DesignerStats(designs: 0, listings: 0, sales: 0, balanceUzs: 0),
  );

  @override
  Future<Result<DesignerProfile>> onboard({
    required String displayName,
    required String legalName,
    required PayoutMethod payoutMethod,
    required String contractVersion,
    required String regulationsHash,
    required String signatureName,
    String? idNumber,
  }) async {
    _profile = DesignerProfile(
      userId: 'mock',
      displayName: displayName,
      kycStatus: KycStatus.pending,
      payoutMethod: payoutMethod,
      contractVersion: contractVersion,
      contractAcceptedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    return Success(_profile!);
  }
}
