import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/models/category_config.dart';
import 'cache_service_interface.dart';

class CacheServiceWeb implements CacheServiceBase {
  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> insertArticles(List<Article> articles) async {}

  @override
  Future<List<Article>> getArticlesByCategory(String category) async => [];

  @override
  Future<bool> isStale(String category) async => true;

  @override
  Future<void> clearExpired() async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> insertCategory(CategoryConfig category) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<List<CategoryConfig>> getCategories() async => [];

  @override
  Future<int> getArticleCount(String categoryId) async => 0;

  @override
  Future<void> savePlaybackState({
    required String category,
    String? categoryUrl,
    required int articleIndex,
    String? articleId,
    required int positionMs,
  }) async {}

  @override
  Future<Map<String, dynamic>?> getPlaybackState() async => null;

  @override
  Future<void> clearPlaybackState() async {}
}

CacheServiceBase createCacheService() => CacheServiceWeb();
