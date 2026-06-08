import 'package:meta/meta.dart';

import '../utils/json.dart';

/// How a print is mapped onto a template (SPEC §6).
enum WarpType { none, cylinder }

/// A rectangular print area on a template photo, in template-pixel space.
/// The print is scaled to fit, respecting aspect ratio, then alpha-composited.
@immutable
class PrintZone {
  const PrintZone({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.rotation = 0,
  });

  final double x;
  final double y;
  final double w;
  final double h;

  /// Degrees, clockwise.
  final double rotation;

  factory PrintZone.fromJson(Map<String, dynamic> json) => PrintZone(
    x: (json['x'] as num? ?? 0).toDouble(),
    y: (json['y'] as num? ?? 0).toDouble(),
    w: (json['w'] as num? ?? 0).toDouble(),
    h: (json['h'] as num? ?? 0).toDouble(),
    rotation: (json['rotation'] as num? ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'rotation': rotation,
  };
}

/// One color/variant of a product, with its template + mapping metadata.
@immutable
class ProductVariant {
  const ProductVariant({
    required this.color,
    required this.templateUrl,
    required this.printZone,
    this.warp = WarpType.none,
  });

  /// Display color key, e.g. `white`, `black`.
  final String color;

  /// Blank product photo in the `product-templates` bucket.
  final String templateUrl;
  final PrintZone printZone;
  final WarpType warp;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    color: json['color'] as String? ?? 'default',
    templateUrl: json['template_url'] as String? ?? '',
    printZone: PrintZone.fromJson(
      (json['print_zone'] as Map<String, dynamic>? ?? const {}),
    ),
    warp: Json.enumByName(WarpType.values, json['warp'], WarpType.none),
  );

  Map<String, dynamic> toJson() => {
    'color': color,
    'template_url': templateUrl,
    'print_zone': printZone.toJson(),
    'warp': warp.name,
  };
}

/// A blank product the platform prints on (t-shirt, hoodie, cap, cup…).
@immutable
class ProductType {
  const ProductType({
    required this.id,
    required this.slug,
    required this.nameRu,
    required this.nameUz,
    required this.nameEn,
    required this.baseCostUzs,
    this.sizes = const [],
    this.variants = const [],
  });

  final String id;
  final String slug;
  final String nameRu;
  final String nameUz;
  final String nameEn;

  /// Blank + printing + packaging cost in UZS (SPEC tooltip §11).
  final int baseCostUzs;

  /// Available sizes (e.g. S–XXL); empty for one-size products like cups.
  final List<String> sizes;
  final List<ProductVariant> variants;

  String nameFor(String languageCode) => switch (languageCode) {
    'uz' => nameUz,
    'en' => nameEn,
    _ => nameRu,
  };

  ProductVariant? variantForColor(String color) {
    for (final v in variants) {
      if (v.color == color) return v;
    }
    return variants.isEmpty ? null : variants.first;
  }

  factory ProductType.fromJson(Map<String, dynamic> json) => ProductType(
    id: json['id'] as String,
    slug: json['slug'] as String,
    nameRu: json['name_ru'] as String? ?? '',
    nameUz: json['name_uz'] as String? ?? '',
    nameEn: json['name_en'] as String? ?? '',
    baseCostUzs: Json.intValue(json['base_cost']),
    sizes:
        (json['sizes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    variants: Json.listOfMaps(
      json['variants'],
    ).map(ProductVariant.fromJson).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name_ru': nameRu,
    'name_uz': nameUz,
    'name_en': nameEn,
    'base_cost': baseCostUzs,
    'sizes': sizes,
    'variants': variants.map((v) => v.toJson()).toList(),
  };
}
