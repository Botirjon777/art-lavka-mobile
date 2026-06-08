import 'package:meta/meta.dart';

import '../utils/json.dart';

/// A line in the customer's cart. Synced to a `cart_items` table so the cart
/// survives reinstall / login on another device (SPEC §7).
@immutable
class CartItem {
  const CartItem({
    required this.id,
    required this.listingId,
    required this.quantity,
    this.size,
    this.color,
    this.titleSnapshot,
    this.mockupUrl,
    this.unitPriceUzs = 0,
    this.available = true,
  });

  final String id;
  final String listingId;
  final int quantity;
  final String? size;
  final String? color;

  // Denormalized for rendering the cart without extra round-trips.
  final String? titleSnapshot;
  final String? mockupUrl;
  final int unitPriceUzs;

  /// Set false when the listing went inactive; UI offers to remove it (SPEC §11).
  final bool available;

  int get lineTotalUzs => unitPriceUzs * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    listingId: json['listing_id'] as String,
    quantity: Json.intValue(json['quantity'], fallback: 1),
    size: Json.stringOrNull(json['size']),
    color: Json.stringOrNull(json['color']),
    titleSnapshot: Json.stringOrNull(json['title_snapshot']),
    mockupUrl: Json.stringOrNull(json['mockup_url']),
    unitPriceUzs: Json.intValue(json['unit_price']),
    available: Json.boolValue(json['available'], fallback: true),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'listing_id': listingId,
    'quantity': quantity,
    'size': size,
    'color': color,
  };

  CartItem copyWith({int? quantity, bool? available}) => CartItem(
    id: id,
    listingId: listingId,
    size: size,
    color: color,
    titleSnapshot: titleSnapshot,
    mockupUrl: mockupUrl,
    unitPriceUzs: unitPriceUzs,
    quantity: quantity ?? this.quantity,
    available: available ?? this.available,
  );
}
