import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';

/// Home banners.
final bannersProvider = FutureProvider.autoDispose<List<Banner>>(
  (ref) async =>
      (await ref.watch(catalogRepositoryProvider).banners()).unwrap(),
);

/// First page of listings for a feed section (slug == null → newest across all).
final feedListingsProvider = FutureProvider.autoDispose
    .family<List<Listing>, String?>(
      (ref, slug) async =>
          (await ref
                  .watch(catalogRepositoryProvider)
                  .listings(categorySlug: slug))
              .unwrap(),
    );
