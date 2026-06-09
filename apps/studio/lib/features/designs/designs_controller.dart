import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';

/// The seller's own designs (with statuses).
final myDesignsProvider = FutureProvider.autoDispose<List<Design>>(
  (ref) async =>
      (await ref.watch(designRepositoryProvider).myDesigns()).unwrap(),
);

/// Product types + categories for the upload form (cached).
final productTypesProvider = FutureProvider<List<ProductType>>(
  (ref) async =>
      (await ref.watch(catalogRepositoryProvider).productTypes()).unwrap(),
);

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) async =>
      (await ref.watch(catalogRepositoryProvider).categories()).unwrap(),
);
