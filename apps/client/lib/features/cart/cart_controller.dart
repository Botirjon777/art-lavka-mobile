import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client-side cart (in-memory). Synced to the server later (SPEC §7 — survives
/// reinstall); for now it lives for the session. Checkout sends item ids to the
/// server, which recomputes prices (the client price here is display-only).
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

/// Total item count (for the cart badge).
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (sum, i) => sum + i.quantity),
);

/// Cart subtotal in UZS (display only).
final cartSubtotalProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (sum, i) => sum + i.lineTotalUzs),
);

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  /// Stable per-variant key so the same listing+size+color merges quantities.
  String _key(String listingId, String? size, String? color) =>
      '$listingId|${size ?? ''}|${color ?? ''}';

  void addListing(
    Listing listing, {
    String? size,
    String? color,
    int quantity = 1,
  }) {
    final id = _key(listing.id, size, color);
    final existing = state.where((i) => i.id == id).firstOrNull;
    if (existing != null) {
      setQuantity(id, existing.quantity + quantity);
      return;
    }
    state = [
      ...state,
      CartItem(
        id: id,
        listingId: listing.id,
        quantity: quantity,
        size: size,
        color: color,
        titleSnapshot: listing.title,
        mockupUrl: listing.mockupUrl,
        unitPriceUzs: listing.priceUzs,
      ),
    ];
  }

  void setQuantity(String id, int quantity) {
    if (quantity <= 0) {
      remove(id);
      return;
    }
    state = [
      for (final i in state)
        if (i.id == id) i.copyWith(quantity: quantity) else i,
    ];
  }

  void remove(String id) => state = [
    for (final i in state)
      if (i.id != id) i,
  ];

  void clear() => state = const [];
}
