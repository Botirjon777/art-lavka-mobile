import 'package:artlavka_client/bootstrap/core_providers.dart';
import 'package:artlavka_client/features/catalog/widgets/product_card.dart';
import 'package:artlavka_client/features/home/home_page.dart';
import 'package:artlavka_client/l10n/l10n.dart';
import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart' hide Banner;
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

class _FakeCatalog extends CatalogRepository {
  _FakeCatalog() : super(ApiClient(tokenStore: TokenStore()));

  @override
  Future<Result<List<Banner>>> banners() async => const Success([]);

  @override
  Future<Result<List<Category>>> categories() async => const Success([
    Category(
      id: 'c1',
      slug: 'memes',
      nameRu: 'Мемы',
      nameUz: 'Memlar',
      nameEn: 'Memes',
    ),
  ]);

  @override
  Future<Result<List<Listing>>> listings({
    String? categorySlug,
    String? query,
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) async => Success([_listing()]);
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
  testWidgets('home renders feed shelves from the repository', (tester) async {
    await tester.pumpWidget(
      _host(const HomePage(), [
        catalogRepositoryProvider.overrideWithValue(_FakeCatalog()),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('New arrivals'), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
  });
}
