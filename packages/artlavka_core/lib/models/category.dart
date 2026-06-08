import 'package:meta/meta.dart';

import '../utils/json.dart';

/// A catalog theme/category (gamers, memes, funny, anime…). SPEC §5.
@immutable
class Category {
  const Category({
    required this.id,
    required this.slug,
    required this.nameRu,
    required this.nameUz,
    required this.nameEn,
    this.sortOrder = 0,
  });

  final String id;
  final String slug;
  final String nameRu;
  final String nameUz;
  final String nameEn;
  final int sortOrder;

  /// Localized label for a BCP-47 [languageCode], defaulting to RU.
  String nameFor(String languageCode) => switch (languageCode) {
    'uz' => nameUz,
    'en' => nameEn,
    _ => nameRu,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    slug: json['slug'] as String,
    nameRu: json['name_ru'] as String? ?? '',
    nameUz: json['name_uz'] as String? ?? '',
    nameEn: json['name_en'] as String? ?? '',
    sortOrder: Json.intValue(json['sort_order']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name_ru': nameRu,
    'name_uz': nameUz,
    'name_en': nameEn,
    'sort_order': sortOrder,
  };
}
