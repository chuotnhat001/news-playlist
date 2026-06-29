import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/models/category_config.dart';
import 'cache_service_interface.dart';

class CacheServiceWeb implements CacheServiceBase {
  final Map<String, CategoryConfig> _categories = {};
  final Map<String, List<Article>> _articles = {};
  Map<String, dynamic>? _playbackState;

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> insertArticles(List<Article> articles) async {
    if (articles.isEmpty) return;
    final categoryId = articles.first.category;
    _articles[categoryId] = List.from(articles);
  }

  @override
  Future<List<Article>> getArticlesByCategory(String category) async {
    return _articles[category] ?? [];
  }

  @override
  Future<bool> isStale(String category) async => true;

  @override
  Future<void> clearExpired() async {}

  @override
  Future<void> clearAll() async {
    _categories.clear();
    _articles.clear();
    _playbackState = null;
  }

  @override
  Future<void> insertCategory(CategoryConfig category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.remove(id);
    _articles.remove(id);
  }

  @override
  Future<List<CategoryConfig>> getCategories() async {
    return _categories.values.toList();
  }

  @override
  Future<int> getArticleCount(String categoryId) async {
    return _articles[categoryId]?.length ?? 0;
  }

  @override
  Future<void> savePlaybackState({
    required String category,
    String? categoryUrl,
    required int articleIndex,
    String? articleId,
    required int positionMs,
  }) async {
    _playbackState = {
      'category': category,
      'category_url': categoryUrl,
      'article_index': articleIndex,
      'article_id': articleId,
      'position_ms': positionMs,
    };
  }

  @override
  Future<Map<String, dynamic>?> getPlaybackState() async => _playbackState;

  @override
  Future<void> clearPlaybackState() async {
    _playbackState = null;
  }
}

CacheServiceBase createCacheService() => CacheServiceWeb();
