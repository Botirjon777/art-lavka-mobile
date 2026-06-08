import 'package:meta/meta.dart';

import '../utils/json.dart';

/// Seller verification state. Studio's dashboard stays locked until
/// [KycStatus.verified] (SPEC §9).
enum KycStatus { none, pending, verified, rejected }

/// How a designer gets paid out.
enum PayoutMethod { card, bank }

/// A designer's public storefront identity + private KYC/contract state.
@immutable
class DesignerProfile {
  const DesignerProfile({
    required this.userId,
    required this.displayName,
    required this.kycStatus,
    required this.createdAt,
    this.bio,
    this.avatarUrl,
    this.payoutMethod,
    this.contractVersion,
    this.contractAcceptedAt,
  });

  /// Same id as the owning [AppUser] (1:1).
  final String userId;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final KycStatus kycStatus;
  final PayoutMethod? payoutMethod;

  /// Regulations version the seller accepted, and when (SPEC §9 enforceability).
  final String? contractVersion;
  final DateTime? contractAcceptedAt;
  final DateTime createdAt;

  /// Gate for Studio dashboard access.
  bool get isVerified => kycStatus == KycStatus.verified;

  factory DesignerProfile.fromJson(Map<String, dynamic> json) =>
      DesignerProfile(
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String? ?? '',
        bio: Json.stringOrNull(json['bio']),
        avatarUrl: Json.stringOrNull(json['avatar_url']),
        kycStatus: Json.enumByName(
          KycStatus.values,
          json['kyc_status'],
          KycStatus.none,
        ),
        payoutMethod: json['payout_method'] == null
            ? null
            : Json.enumByName(
                PayoutMethod.values,
                json['payout_method'],
                PayoutMethod.card,
              ),
        contractVersion: Json.stringOrNull(json['contract_version']),
        contractAcceptedAt: Json.dateOrNull(json['contract_accepted_at']),
        createdAt: Json.date(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'kyc_status': kycStatus.name,
    'payout_method': payoutMethod?.name,
    'contract_version': contractVersion,
    'contract_accepted_at': contractAcceptedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  DesignerProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    KycStatus? kycStatus,
    PayoutMethod? payoutMethod,
    String? contractVersion,
    DateTime? contractAcceptedAt,
  }) => DesignerProfile(
    userId: userId,
    createdAt: createdAt,
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    kycStatus: kycStatus ?? this.kycStatus,
    payoutMethod: payoutMethod ?? this.payoutMethod,
    contractVersion: contractVersion ?? this.contractVersion,
    contractAcceptedAt: contractAcceptedAt ?? this.contractAcceptedAt,
  );
}
