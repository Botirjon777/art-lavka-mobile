import 'package:artlavka_client/bootstrap/core_providers.dart';
import 'package:artlavka_client/features/catalog/catalog_page.dart';
import 'package:artlavka_client/features/catalog/widgets/product_card.dart';
import 'package:artlavka_client/features/product/product_page.dart';
import 'package:artlavka_client/l10n/l10n.dart';
import 'package:artlavka_client/ui/async_views.dart';
import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _sampleListing() => Listing(
  id: 'l1',
  designId: 'd1',
  productTypeId: 'p1',
  royaltyUzs: 20000,
  baseCostUzs: 60000,
  active: true,
  createdAt: DateTime(2026),
  title: 'Cool Tee',
  designerName: 'Asha',
  ratingAvg: 4.5,
  ratingCount: 3,
);

Category _sampleCategory() => const Category(
  id: 'c1',
  slug: 'memes',
  nameRu: 'Мемы',
  nameUz: 'Memlar',
  nameEn: 'Memes',
);

/// Fakes extend the concrete repos and override the methods under test. The
/// super ctor needs an ApiClient, but it's never called (no network).
class _FakeCatalog extends CatalogRepository {
  _FakeCatalog({required this.listings_, required this.categories_})
    : super(ApiClient(tokenStore: TokenStore()));
  final List<Listing> listings_;
  final List<Category> categories_;

  @override
  Future<Result<List<Listing>>> listings({
    String? categorySlug,
    String? query,
    String? sort,
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) async => Success(page == 0 ? listings_ : const []);

  @override
  Future<Result<List<Category>>> categories() async => Success(categories_);

  @override
  Future<Result<Listing>> listing(String id) async => Success(_sampleListing());
}

class _FakeOrders extends OrderRepository {
  _FakeOrders() : super(ApiClient(tokenStore: TokenStore()));
  @override
  Future<Result<List<Review>>> reviewsForDesign(String designId) async =>
      const Success([]);
}

Widget _host(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  testWidgets('catalog renders product cards from the repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const CatalogPage(), [
        catalogRepositoryProvider.overrideWithValue(
          _FakeCatalog(
            listings_: [_sampleListing()],
            categories_: [_sampleCategory()],
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProductCard), findsOneWidget);
    expect(find.text('Cool Tee'), findsWidgets);
  });

  testWidgets('catalog shows the empty state when there are no listings', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const CatalogPage(), [
        catalogRepositoryProvider.overrideWithValue(
          _FakeCatalog(listings_: const [], categories_: const []),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('product page shows detail + add to cart', (tester) async {
    // Tall surface so the lazy ListView builds the button below the mockup.
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(const ProductPage(listingId: 'l1'), [
        catalogRepositoryProvider.overrideWithValue(
          _FakeCatalog(listings_: const [], categories_: const []),
        ),
        orderRepositoryProvider.overrideWithValue(_FakeOrders()),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cool Tee'), findsWidgets);
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
  });
}
