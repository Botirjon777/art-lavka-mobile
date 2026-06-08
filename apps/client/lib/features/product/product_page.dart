import 'package:artlavka_core/artlavka_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/result_x.dart';
import '../../l10n/l10n.dart';
import '../../ui/async_views.dart';
import '../../ui/cart_badge.dart';
import '../cart/cart_controller.dart';
import 'product_controller.dart';

/// Product page: mockup, price, designer, rating, reviews, add-to-cart (SPEC §4).
class ProductPage extends ConsumerWidget {
  const ProductPage({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final listing = ref.watch(listingProvider(listingId));

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.valueOrNull?.title ?? t.appName),
        actions: const [CartBadge()],
      ),
      body: listing.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetryView(
          message: failureMessage(context, e),
          onRetry: () => ref.invalidate(listingProvider(listingId)),
        ),
        data: (l) => _Detail(listing: l),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.space * 2),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: AspectRatio(
            aspectRatio: 1,
            child: (listing.mockupUrl == null || listing.mockupUrl!.isEmpty)
                ? Container(color: AppColors.surfaceMuted)
                : CachedNetworkImage(
                    imageUrl: listing.mockupUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: AppColors.surfaceMuted),
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.surfaceMuted),
                  ),
          ),
        ),
        const SizedBox(height: AppTheme.space * 2),
        Text(listing.title ?? '', style: text.headlineMedium),
        if (listing.designerName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              t.productByDesigner(listing.designerName!),
              style: text.bodyMedium,
            ),
          ),
        const SizedBox(height: AppTheme.space),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Money.format(listing.priceUzs), style: text.titleLarge),
            if (listing.ratingCount > 0)
              RatingStars(
                rating: listing.ratingAvg ?? 0,
                count: listing.ratingCount,
              ),
          ],
        ),
        const SizedBox(height: AppTheme.space * 2),
        FilledButton.icon(
          onPressed: () {
            ref.read(cartProvider.notifier).addListing(listing);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(t.addedToCart)));
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: Text(t.addToCart),
        ),
        const SizedBox(height: AppTheme.space * 3),
        Text(t.productReviews, style: text.titleLarge),
        const SizedBox(height: AppTheme.space),
        _Reviews(designId: listing.designId),
      ],
    );
  }
}

class _Reviews extends ConsumerWidget {
  const _Reviews({required this.designId});
  final String designId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final reviews = ref.watch(designReviewsProvider(designId));
    return reviews.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppTheme.space * 2),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        t.productNoReviews,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            t.productNoReviews,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return Column(children: [for (final r in list) _ReviewTile(review: r)]);
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(rating: review.rating.toDouble(), size: 14),
              const SizedBox(width: AppTheme.space),
              if (review.customerName != null)
                Text(review.customerName!, style: text.bodySmall),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(review.comment!, style: text.bodyMedium),
            ),
        ],
      ),
    );
  }
}
