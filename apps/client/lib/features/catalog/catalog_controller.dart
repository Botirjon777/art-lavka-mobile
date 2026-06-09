import 'package:artlavka_core/artlavka_core.dart';
// Hide foundation's `Category` annotation — it collides with our model.
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';

/// Categories for the filter row. Cached (not autoDispose) so it's fetched once
/// and shared by the home shelves + the catalog filter.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) async =>
      (await ref.watch(catalogRepositoryProvider).categories()).unwrap(),
);

/// Selected category slug (null = all).
final selectedCategoryProvider = StateProvider.autoDispose<String?>(
  (_) => null,
);

/// Paginated listings for the current category.
@immutable
class ListingsState {
  const ListingsState({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<Listing> items;
  final bool hasMore;
  final bool loadingMore;

  ListingsState copyWith({
    List<Listing>? items,
    bool? hasMore,
    bool? loadingMore,
  }) => ListingsState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

final listingsProvider =
    AsyncNotifierProvider.autoDispose<ListingsNotifier, ListingsState>(
      ListingsNotifier.new,
    );

class ListingsNotifier extends AutoDisposeAsyncNotifier<ListingsState> {
  int _page = 0;
  String? _category;

  CatalogRepository get _repo => ref.read(catalogRepositoryProvider);

  @override
  Future<ListingsState> build() async {
    _category = ref.watch(selectedCategoryProvider);
    _page = 0;
    final items = (await _repo.listings(categorySlug: _category)).unwrap();
    return ListingsState(
      items: items,
      hasMore: items.length >= AppConstants.pageSize,
    );
  }

  /// Append the next page; no-op if already loading or no more.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    final result = await _repo.listings(
      categorySlug: _category,
      page: _page + 1,
    );
    result.fold((items) {
      _page += 1;
      state = AsyncData(
        ListingsState(
          items: [...current.items, ...items],
          hasMore: items.length >= AppConstants.pageSize,
        ),
      );
    }, (_) => state = AsyncData(current.copyWith(loadingMore: false)));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
