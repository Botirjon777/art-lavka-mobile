import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';
import '../../l10n/l10n.dart';
import '../../ui/async_views.dart';
import '../../ui/cart_badge.dart';
import 'catalog_controller.dart';
import 'widgets/product_card.dart';

/// Catalog: category filter + paginated product grid with loading/empty/error
/// states and pull-to-refresh / infinite scroll (SPEC §4, §7).
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(listingsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final listings = ref.watch(listingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.catalogTitle), actions: const [CartBadge()]),
      body: Column(
        children: [
          const _CategoryFilter(),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(listingsProvider.notifier).refresh(),
              child: listings.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorRetryView(
                  message: failureMessage(context, e),
                  onRetry: () => ref.invalidate(listingsProvider),
                ),
                data: (state) => state.items.isEmpty
                    ? _emptyScroll(t.catalogEmpty)
                    : _grid(state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RefreshIndicator needs a scrollable child even when empty.
  Widget _emptyScroll(String message) => ListView(
    children: [
      const SizedBox(height: 80),
      EmptyView(message: message, icon: Icons.storefront_outlined),
    ],
  );

  Widget _grid(ListingsState state) {
    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(AppTheme.space * 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppTheme.space * 2,
        crossAxisSpacing: AppTheme.space * 2,
        childAspectRatio: 0.62,
      ),
      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= state.items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final listing = state.items[i];
        return ProductCard(
          listing: listing,
          onTap: () => context.push('/product/${listing.id}'),
        );
      },
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final lang = ref.watch(localeProvider).languageCode;
    final selected = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(categoriesProvider);

    return SizedBox(
      height: 56,
      child: categories.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (cats) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space * 2),
          children: [
            _chip(
              ref,
              label: t.catalogAll,
              slug: null,
              selected: selected == null,
            ),
            for (final c in cats)
              _chip(
                ref,
                label: c.nameFor(lang),
                slug: c.slug,
                selected: selected == c.slug,
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    WidgetRef ref, {
    required String label,
    required String? slug,
    required bool selected,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          ref.read(selectedCategoryProvider.notifier).state = slug,
    ),
  );
}
