import 'package:artlavka_client/bootstrap/core_providers.dart';
import 'package:artlavka_client/features/orders/order_detail_page.dart';
import 'package:artlavka_client/features/orders/orders_list_page.dart';
import 'package:artlavka_client/l10n/l10n.dart';
import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

OrderItem _item() => const OrderItem(
  id: 'oi1',
  orderId: 'o1',
  listingId: 'l1',
  designId: 'd1',
  productTypeId: 'p1',
  quantity: 2,
  unitBaseCostUzs: 60000,
  unitRoyaltyUzs: 20000,
  titleSnapshot: 'Cool Tee',
);

Order _order() => Order(
  id: 'o1-abc',
  customerId: 'u1',
  status: OrderStatus.delivered,
  subtotalUzs: 160000,
  shippingUzs: 0,
  totalUzs: 160000,
  items: [_item()],
  createdAt: DateTime(2026),
  deliveredAt: DateTime(2026, 1, 2),
);

class _FakeOrders extends OrderRepository {
  _FakeOrders() : super(ApiClient(tokenStore: TokenStore()));

  @override
  Future<Result<List<Order>>> myOrders({
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) async => Success([_order()]);

  @override
  Future<Result<Order>> order(String id) async => Success(_order());
}

Widget _host(Widget child) => ProviderScope(
  overrides: [orderRepositoryProvider.overrideWithValue(_FakeOrders())],
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  testWidgets('orders list shows the order with its status', (tester) async {
    await tester.pumpWidget(_host(const OrdersListPage()));
    await tester.pumpAndSettle();
    expect(find.text('Delivered'), findsOneWidget);
  });

  testWidgets('order detail shows timeline, item and a rate action', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const OrderDetailPage(orderId: 'o1-abc')));
    await tester.pumpAndSettle();
    expect(find.text('Cool Tee'), findsOneWidget);
    // Delivered + not reviewed → a Rate button is offered.
    expect(find.text('Rate'), findsOneWidget);
  });
}
