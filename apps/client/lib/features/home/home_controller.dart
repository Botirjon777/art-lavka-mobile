import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';

/// A home feed shelf is identified by an optional category + sort.
typedef FeedQuery = ({String? category, String? sort});

/// Home banners. NOT autoDispose → cached for the session, so scrolling the
/// home up/down never refetches (re-watching returns the cached value).
final bannersProvider = FutureProvider<List<Banner>>(
  (ref) async =>
      (await ref.watch(catalogRepositoryProvider).banners()).unwrap(),
);

/// First page of listings for a feed shelf. Cached per [FeedQuery].
final feedListingsProvider = FutureProvider.family<List<Listing>, FeedQuery>(
  (ref, q) async =>
      (await ref
              .watch(catalogRepositoryProvider)
              .listings(categorySlug: q.category, sort: q.sort))
          .unwrap(),
);
