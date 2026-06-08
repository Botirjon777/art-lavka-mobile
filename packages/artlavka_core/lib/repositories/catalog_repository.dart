import '../config/constants.dart';
import '../models/banner.dart';
import '../models/category.dart';
import '../models/listing.dart';
import '../models/product_type.dart';
import '../services/api_client.dart';
import '../utils/error_mapper.dart';
import '../utils/result.dart';

/// Read path for the public catalog (BACKEND_NODE.md §5). All list queries are
/// paginated server-side; the page endpoints return `{ data, page, ... }`.
class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<Result<List<Banner>>> banners() => ErrorMapper.guard(() async {
    final data = await _api.get('/catalog/banners') as List;
    return data.map((e) => Banner.fromJson(_map(e))).toList();
  });

  Future<Result<List<Category>>> categories() => ErrorMapper.guard(() async {
    final data = await _api.get('/catalog/categories') as List;
    return data.map((e) => Category.fromJson(_map(e))).toList();
  });

  Future<Result<List<ProductType>>> productTypes() =>
      ErrorMapper.guard(() async {
        final data = await _api.get('/catalog/product-types') as List;
        return data.map((e) => ProductType.fromJson(_map(e))).toList();
      });

  Future<Result<List<Listing>>> listings({
    String? categorySlug,
    String? query,
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) => ErrorMapper.guard(() async {
    final res =
        await _api.get(
              '/catalog/listings',
              query: {
                'page': page,
                if (categorySlug != null && categorySlug.isNotEmpty)
                  'category': categorySlug,
                if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
              },
            )
            as Map;
    return _listFrom(res).map((e) => Listing.fromJson(_map(e))).toList();
  });

  Future<Result<Listing>> listing(String id) => ErrorMapper.guard(() async {
    final data = await _api.get('/catalog/listings/$id') as Map;
    return Listing.fromJson(data.cast<String, dynamic>());
  });

  // --- helpers ---------------------------------------------------------------

  Map<String, dynamic> _map(Object? e) => (e as Map).cast<String, dynamic>();

  List<dynamic> _listFrom(Map<dynamic, dynamic> res) =>
      (res['data'] as List?) ?? const [];
}
