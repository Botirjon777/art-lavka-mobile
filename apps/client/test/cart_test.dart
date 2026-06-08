import 'package:artlavka_client/features/cart/cart_controller.dart';
import 'package:artlavka_client/features/cart/cart_page.dart';
import 'package:artlavka_client/l10n/l10n.dart';
import 'package:artlavka_client/ui/async_views.dart';
import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _listing() => Listing(
  id: 'l1',
  designId: 'd1',
  productTypeId: 'p1',
  royaltyUzs: 20000,
  baseCostUzs: 60000,
  active: true,
  createdAt: DateTime(2026),
  title: 'Cool Tee',
);

Widget _host(Widget child, ProviderContainer container) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  group('CartNotifier', () {
    test('add, merge, subtotal, remove', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final cart = container.read(cartProvider.notifier);

      cart.addListing(_listing());
      cart.addListing(_listing()); // same variant → merges
      expect(container.read(cartProvider).length, 1);
      expect(container.read(cartCountProvider), 2);
      expect(container.read(cartSubtotalProvider), 80000 * 2);

      cart.addListing(_listing(), size: 'L'); // different variant → new line
      expect(container.read(cartProvider).length, 2);

      cart.setQuantity('l1||', 0); // qty 0 removes
      expect(container.read(cartProvider).length, 1);
    });
  });

  testWidgets('cart shows empty state', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(_host(const CartPage(), container));
    await tester.pumpAndSettle();
    expect(find.byType(EmptyView), findsOneWidget);
  });

  testWidgets('cart shows a seeded item and checkout', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).addListing(_listing());

    await tester.pumpWidget(_host(const CartPage(), container));
    await tester.pumpAndSettle();
    expect(find.text('Cool Tee'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);
  });
}
