import 'package:artlavka_core/artlavka_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/core_providers.dart';
import '../../catalog/catalog_controller.dart';

/// Swiper for a product's images (SPEC §6): page 1 is the print itself, page 2
/// previews it "on the product" (t-shirt / cup …). Once the backend produces
/// real composited mockups, add their URLs as extra pages here.
class ProductImageSwiper extends ConsumerStatefulWidget {
  const ProductImageSwiper({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<ProductImageSwiper> createState() => _ProductImageSwiperState();
}

class _ProductImageSwiperState extends ConsumerState<ProductImageSwiper> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final productName = ref
        .watch(productTypesProvider)
        .maybeWhen(
          data: (types) {
            for (final p in types) {
              if (p.id == widget.listing.productTypeId) return p.nameFor(lang);
            }
            return null;
          },
          orElse: () => null,
        );
    final url = widget.listing.mockupUrl;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: AspectRatio(
            aspectRatio: 1,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                _PrintView(url: url),
                _OnProductView(url: url, productName: productName),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 2; i++)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index ? AppColors.accent : AppColors.border,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PrintView extends StatelessWidget {
  const _PrintView({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(color: AppColors.surfaceMuted);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppColors.surfaceMuted),
      errorWidget: (_, _, _) => Container(color: AppColors.surfaceMuted),
    );
  }
}

/// Stylized "print on the product" preview: the print centered on a neutral
/// product surface with the product name. (Placeholder for server mockups.)
class _OnProductView extends StatelessWidget {
  const _OnProductView({this.url, this.productName});
  final String? url;
  final String? productName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppTheme.space * 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space * 3),
                    child: (url == null || url!.isEmpty)
                        ? const SizedBox.shrink()
                        : CachedNetworkImage(
                            imageUrl: url!,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (productName != null) ...[
            const SizedBox(height: AppTheme.space),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.checkroom,
                  size: 16,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  productName!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
