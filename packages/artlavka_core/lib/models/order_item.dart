import 'package:meta/meta.dart';

import '../utils/json.dart';

/// A line in an order. ALL prices here are **snapshots** taken at order time
/// so historical orders never change when a listing is edited (SPEC §13).
@immutable
class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.listingId,
    required this.designId,
    required this.productTypeId,
    required this.quantity,
    required this.unitBaseCostUzs,
    required this.unitRoyaltyUzs,
    this.titleSnapshot,
    this.mockupUrlSnapshot,
    this.size,
    this.color,
    this.reviewed = false,
  });

  final String id;
  final String orderId;
  final String listingId;
  final String designId;
  final String productTypeId;
  final int quantity;

  // Snapshotted unit prices (UZS).
  final int unitBaseCostUzs;
  final int unitRoyaltyUzs;

  final String? titleSnapshot;
  final String? mockupUrlSnapshot;
  final String? size;
  final String? color;

  /// Whether the customer has already reviewed this delivered item.
  final bool reviewed;

  int get unitPriceUzs => unitBaseCostUzs + unitRoyaltyUzs;
  int get lineTotalUzs => unitPriceUzs * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as String,
    orderId: json['order_id'] as String,
    listingId: json['listing_id'] as String,
    designId: json['design_id'] as String,
    productTypeId: json['product_type_id'] as String,
    quantity: Json.intValue(json['quantity'], fallback: 1),
    unitBaseCostUzs: Json.intValue(json['unit_base_cost']),
    unitRoyaltyUzs: Json.intValue(json['unit_royalty']),
    titleSnapshot: Json.stringOrNull(json['title_snapshot']),
    mockupUrlSnapshot: Json.stringOrNull(json['mockup_url_snapshot']),
    size: Json.stringOrNull(json['size']),
    color: Json.stringOrNull(json['color']),
    reviewed: Json.boolValue(json['reviewed']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'listing_id': listingId,
    'design_id': designId,
    'product_type_id': productTypeId,
    'quantity': quantity,
    'unit_base_cost': unitBaseCostUzs,
    'unit_royalty': unitRoyaltyUzs,
    'title_snapshot': titleSnapshot,
    'mockup_url_snapshot': mockupUrlSnapshot,
    'size': size,
    'color': color,
    'reviewed': reviewed,
  };
}
