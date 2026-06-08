import 'package:artlavka_core/artlavka_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../ui/async_views.dart';

/// Catalog card: mockup, title, designer, price, rating (SPEC §10). The art is
/// the hero — image fills the top, text stays quiet below.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: _Mockup(url: listing.mockupUrl),
            ),
          ),
          const SizedBox(height: AppTheme.space),
          Text(
            listing.title ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium,
          ),
          if (listing.designerName != null)
            Text(
              listing.designerName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          const SizedBox(height: 2),
          Text(Money.format(listing.priceUzs), style: text.labelLarge),
          if (listing.ratingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: RatingStars(
                rating: listing.ratingAvg ?? 0,
                count: listing.ratingCount,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }
}

class _Mockup extends StatelessWidget {
  const _Mockup({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.surfaceMuted,
        child: const Icon(Icons.image_outlined, color: AppColors.inkFaint),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppColors.surfaceMuted),
      errorWidget: (_, _, _) => Container(
        color: AppColors.surfaceMuted,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.inkFaint,
        ),
      ),
    );
  }
}
