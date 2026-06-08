import 'package:meta/meta.dart';

import '../utils/json.dart';

/// A design offered on a specific product type at a set royalty.
///
/// Price is computed server-side as `base_cost + royalty` (SPEC §5 — never
/// trust a client price). The client reads [priceUzs] for display only; the
/// `create-order` edge function recomputes it at order time.
@immutable
class Listing {
  const Listing({
    required this.id,
    required this.designId,
    required this.productTypeId,
    required this.royaltyUzs,
    required this.baseCostUzs,
    required this.active,
    required this.createdAt,
    this.title,
    this.designerName,
    this.mockupUrl,
    this.ratingAvg,
    this.ratingCount = 0,
  });

  final String id;
  final String designId;
  final String productTypeId;

  /// Designer's earnings per item (UZS).
  final int royaltyUzs;

  /// Blank + print + packaging (UZS), snapshotted from the product type.
  final int baseCostUzs;
  final bool active;
  final DateTime createdAt;

  // --- Denormalized for catalog cards (optional joins) ----------------------
  final String? title;
  final String? designerName;

  /// Pre-rendered mockup from the `mockups` bucket (SPEC §6 Strategy A).
  final String? mockupUrl;
  final double? ratingAvg;
  final int ratingCount;

  /// Display price. Authoritative price is recomputed server-side at checkout.
  int get priceUzs => baseCostUzs + royaltyUzs;

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
    id: json['id'] as String,
    designId: json['design_id'] as String,
    productTypeId: json['product_type_id'] as String,
    royaltyUzs: Json.intValue(json['royalty']),
    baseCostUzs: Json.intValue(json['base_cost']),
    active: Json.boolValue(json['active'], fallback: true),
    createdAt: Json.date(json['created_at']),
    title: Json.stringOrNull(json['title']),
    designerName: Json.stringOrNull(json['designer_name']),
    mockupUrl: Json.stringOrNull(json['mockup_url']),
    ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
    ratingCount: Json.intValue(json['rating_count']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'design_id': designId,
    'product_type_id': productTypeId,
    'royalty': royaltyUzs,
    'base_cost': baseCostUzs,
    'active': active,
    'created_at': createdAt.toIso8601String(),
  };

  Listing copyWith({int? royaltyUzs, bool? active}) => Listing(
    id: id,
    designId: designId,
    productTypeId: productTypeId,
    baseCostUzs: baseCostUzs,
    createdAt: createdAt,
    title: title,
    designerName: designerName,
    mockupUrl: mockupUrl,
    ratingAvg: ratingAvg,
    ratingCount: ratingCount,
    royaltyUzs: royaltyUzs ?? this.royaltyUzs,
    active: active ?? this.active,
  );
}
