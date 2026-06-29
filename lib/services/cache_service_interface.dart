import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/models/category_config.dart';

abstract class CacheServiceBase {
  bool get isReady;
  Future<void> init();
  Future<void> insertArticles(List<Article> articles);
  Future<List<Article>> getArticlesByCategory(String category);
  Future<bool> isStale(String category);
  Future<void> clearExpired();
  Future<void> clearAll();
  Future<void> insertCategory(CategoryConfig category);
  Future<void> deleteCategory(String id);
  Future<List<CategoryConfig>> getCategories();
  Future<int> getArticleCount(String categoryId);
  Future<void> savePlaybackState({
    required String category,
    String? categoryUrl,
    required int articleIndex,
    String? articleId,
    required int positionMs,
  });
  Future<Map<String, dynamic>?> getPlaybackState();
  Future<void> clearPlaybackState();
}

CacheServiceBase createCacheService() =>
    throw UnsupportedError('Platform implementation not loaded');
