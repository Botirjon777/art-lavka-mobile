import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';

/// One listing's detail (by listing id).
final listingProvider = FutureProvider.autoDispose.family<Listing, String>(
  (ref, id) async =>
      (await ref.watch(catalogRepositoryProvider).listing(id)).unwrap(),
);

/// Reviews for a design (by design id).
final designReviewsProvider = FutureProvider.autoDispose
    .family<List<Review>, String>(
      (ref, designId) async =>
          (await ref.watch(orderRepositoryProvider).reviewsForDesign(designId))
              .unwrap(),
    );
