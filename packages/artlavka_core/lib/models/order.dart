import 'package:meta/meta.dart';

import '../utils/json.dart';
import 'order_item.dart';

/// Lifecycle of an order. Set/advanced server-side (edge functions + webhook).
enum OrderStatus {
  pending, // created, awaiting payment
  paid, // payment confirmed, queued for production
  inProduction,
  shipped,
  delivered,
  cancelled,
  refunded,
}

/// Local payment providers (SPEC §1).
enum PaymentProvider { click, payme, uzum }

/// A customer order. Money fields are UZS `int`, computed server-side.
@immutable
class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.status,
    required this.subtotalUzs,
    required this.shippingUzs,
    required this.totalUzs,
    required this.createdAt,
    this.items = const [],
    this.paymentProvider,
    this.shippingAddress,
    this.paidAt,
    this.deliveredAt,
  });

  final String id;
  final String customerId;
  final OrderStatus status;

  final int subtotalUzs;
  final int shippingUzs;
  final int totalUzs;

  final List<OrderItem> items;
  final PaymentProvider? paymentProvider;
  final String? shippingAddress;

  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;

  bool get isPaid => paidAt != null;
  bool get isDelivered => status == OrderStatus.delivered;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    customerId: json['customer_id'] as String,
    status: Json.enumByName(
      OrderStatus.values,
      json['status'],
      OrderStatus.pending,
    ),
    subtotalUzs: Json.intValue(json['subtotal']),
    shippingUzs: Json.intValue(json['shipping']),
    totalUzs: Json.intValue(json['total']),
    items: Json.listOfMaps(
      json['order_items'],
    ).map(OrderItem.fromJson).toList(),
    paymentProvider: json['payment_provider'] == null
        ? null
        : Json.enumByName(
            PaymentProvider.values,
            json['payment_provider'],
            PaymentProvider.click,
          ),
    shippingAddress: Json.stringOrNull(json['shipping_address']),
    createdAt: Json.date(json['created_at']),
    paidAt: Json.dateOrNull(json['paid_at']),
    deliveredAt: Json.dateOrNull(json['delivered_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'status': status.name,
    'subtotal': subtotalUzs,
    'shipping': shippingUzs,
    'total': totalUzs,
    'payment_provider': paymentProvider?.name,
    'shipping_address': shippingAddress,
    'created_at': createdAt.toIso8601String(),
    'paid_at': paidAt?.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
  };
}
