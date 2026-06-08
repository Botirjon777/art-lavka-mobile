import '../models/cart_item.dart';
import '../models/order.dart';
import '../utils/error_mapper.dart';
import '../utils/json.dart';
import '../utils/result.dart';
import 'api_client.dart';

/// A payment intent returned by `POST /orders`: the created order id plus the
/// URL/token the app hands to the provider checkout.
class PaymentIntent {
  const PaymentIntent({
    required this.orderId,
    required this.provider,
    required this.checkoutUrl,
    this.amountUzs = 0,
    this.providerRef,
  });

  final String orderId;
  final PaymentProvider provider;
  final String checkoutUrl;
  final int amountUzs;
  final String? providerRef;

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => PaymentIntent(
    orderId: json['order_id'] as String,
    provider: PaymentProvider.values.firstWhere(
      (p) => p.name == json['provider'],
      orElse: () => PaymentProvider.click,
    ),
    checkoutUrl: json['checkout_url'] as String? ?? '',
    amountUzs: Json.intValue(json['amount']),
    providerRef: Json.stringOrNull(json['provider_ref']),
  );
}

/// Talks to the server for anything money-related. The client NEVER computes or
/// trusts a price — `POST /orders` recomputes it server-side (SPEC §1/§5).
class PaymentService {
  PaymentService(this._api);
  final ApiClient _api;

  /// Create an order from cart items and get a payment intent back. Only
  /// ids/quantities/options are sent — the server recomputes + snapshots prices.
  Future<Result<PaymentIntent>> createOrder({
    required List<CartItem> items,
    required PaymentProvider provider,
    required String shippingAddress,
  }) => ErrorMapper.guard(() async {
    final data =
        await _api.post(
              '/orders',
              data: {
                'paymentProvider': provider.name,
                'shippingAddress': shippingAddress,
                'items': items
                    .map(
                      (i) => {
                        'listingId': i.listingId,
                        'quantity': i.quantity,
                        'size': ?i.size,
                        'color': ?i.color,
                      },
                    )
                    .toList(),
              },
            )
            as Map;
    return PaymentIntent.fromJson(data.cast<String, dynamic>());
  });
}
