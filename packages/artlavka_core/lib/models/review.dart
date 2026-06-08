import 'package:meta/meta.dart';

import '../utils/json.dart';

/// A customer rating for one delivered order item (1–5). SPEC §5.
@immutable
class Review {
  const Review({
    required this.id,
    required this.orderItemId,
    required this.customerId,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.customerName,
  });

  final String id;
  final String orderItemId;
  final String customerId;

  /// 1–5.
  final int rating;
  final String? comment;
  final DateTime createdAt;

  /// Denormalized display name when joined for product pages (optional).
  final String? customerName;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    orderItemId: json['order_item_id'] as String,
    customerId: json['customer_id'] as String,
    rating: Json.intValue(json['rating']).clamp(1, 5),
    comment: Json.stringOrNull(json['comment']),
    createdAt: Json.date(json['created_at']),
    customerName: Json.stringOrNull(json['customer_name']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_item_id': orderItemId,
    'customer_id': customerId,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
  };
}
