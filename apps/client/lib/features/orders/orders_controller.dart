import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../bootstrap/result_x.dart';

/// The caller's orders, newest first.
final myOrdersProvider = FutureProvider.autoDispose<List<Order>>(
  (ref) async => (await ref.watch(orderRepositoryProvider).myOrders()).unwrap(),
);

/// One order (by id), for the tracking screen.
final orderProvider = FutureProvider.autoDispose.family<Order, String>(
  (ref, id) async =>
      (await ref.watch(orderRepositoryProvider).order(id)).unwrap(),
);
