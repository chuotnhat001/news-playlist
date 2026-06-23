import 'dart:async';

import '../models/article.dart';
import '../models/category_config.dart';
import 'cache_service.dart';
import 'crawler_service.dart';

class ContentService {
  final CacheService _cacheService;
  final Map<String, CrawlerService> _crawlerServices;

  final _refreshController = StreamController<String>.broadcast();
  Stream<String> get onBackgroundRefresh => _refreshController.stream;

  static const categoryUrls = {
    'cong-nghe': {
      'dantri': 'https://dantri.com.vn/suc-manh-so.htm',
      'soha': 'https://soha.vn/cong-nghe.htm',
    },
    'kinh-doanh': {
      'dantri': 'https://dantri.com.vn/kinh-doanh.htm',
      'soha': 'https://soha.vn/kinh-doanh.htm',
    },
    'chung-khoan': {
      'dantri': 'https://dantri.com.vn/kinh-doanh/chung-khoan.htm',
      'soha': 'https://soha.vn/kinh-doanh.htm',
    },
  };

  ContentService({
    required CacheService cacheService,
    required Map<String, CrawlerService> crawlerServices,
  })  : _cacheService = cacheService,
        _crawlerServices = crawlerServices;

  Future<void> init() async {
    await _cacheService.init();
    await _cacheService.clearExpired();
  }

  // Custom categories CRUD
  Future<List<CategoryConfig>> getCustomCategories() async {
    return _cacheService.getCategories();
  }

  Future<void> addCategory(CategoryConfig category) async {
    await _cacheService.insertCategory(category);
  }

  Future<void> removeCategory(String id) async {
    await _cacheService.deleteCategory(id);
  }

  Future<int> getArticleCount(String categoryId) async {
    return _cacheService.getArticleCount(categoryId);
  }

  Future<List<Article>> getArticles(String category) =>
      _fetchWithFallback(categoryId: category, crawl: () => _crawlAndCache(category));

  Future<List<Article>> getArticlesFromUrl(String url, String categoryId) =>
      _fetchWithFallback(categoryId: categoryId, crawl: () => _crawlUrlAndCache(url, categoryId));

  Future<List<Article>> refreshCategory(String category) =>
      _fetchWithFallback(categoryId: category, crawl: () => _crawlAndCache(category), forceRefresh: true);

  Future<List<Article>> refreshUrl(String url, String categoryId) =>
      _fetchWithFallback(categoryId: categoryId, crawl: () => _crawlUrlAndCache(url, categoryId), forceRefresh: true);

  Future<List<Article>> _fetchWithFallback({
    required String categoryId,
    required Future<List<Article>> Function() crawl,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      try {
        return await crawl();
      } catch (_) {
        return _cacheService.getArticlesByCategory(categoryId);
      }
    }

    final stale = await _cacheService.isStale(categoryId);
    if (!stale) {
      return _cacheService.getArticlesByCategory(categoryId);
    }

    // Stale-while-revalidate: return cached data immediately, crawl in background
    final cached = await _cacheService.getArticlesByCategory(categoryId);
    if (cached.isNotEmpty) {
      // Fire and forget background refresh, notify listeners on completion
      crawl().then((_) {
        _refreshController.add(categoryId);
      }).catchError((_) {});
      return cached;
    }

    // No cache at all — must crawl synchronously
    try {
      return await crawl();
    } catch (_) {
      return [];
    }
  }

  Future<List<Article>> _crawlUrlAndCache(String url, String categoryId) async {
    final uri = Uri.parse(url);
    final host = uri.host;

    CrawlerService? crawler;
    if (host.contains('soha.vn')) {
      crawler = _crawlerServices['soha'];
    } else if (host.contains('dantri.com.vn')) {
      crawler = _crawlerServices['dantri'];
    }
    if (crawler == null) return [];

    final result = await crawler.crawlCategory(url, categoryId);
    if (result.articles.isNotEmpty) {
      await _cacheService.insertArticles(result.articles);
    }

    final articles = result.articles.toList();
    articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }

  Future<List<Article>> _crawlAndCache(String category) async {
    final urls = categoryUrls[category];
    if (urls == null) return [];

    final allArticles = <Article>[];

    for (final entry in _crawlerServices.entries) {
      final sourceName = entry.key;
      final crawler = entry.value;
      final listingUrl = urls[sourceName];

      if (listingUrl == null) continue;

      final result = await crawler.crawlCategory(listingUrl, category);
      allArticles.addAll(result.articles);
    }

    if (allArticles.isNotEmpty) {
      await _cacheService.insertArticles(allArticles);
    }

    allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return allArticles;
  }

  void dispose() {
    _refreshController.close();
  }
}
