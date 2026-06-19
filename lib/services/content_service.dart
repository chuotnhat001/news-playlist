import '../models/article.dart';
import 'cache_service.dart';
import 'crawler_service.dart';

class ContentService {
  final CacheService _cacheService;
  final Map<String, CrawlerService> _crawlerServices;

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

  Future<List<Article>> getArticles(String category) async {
    final stale = await _cacheService.isStale(category);
    if (!stale) {
      return _cacheService.getArticlesByCategory(category);
    }

    try {
      return await _crawlAndCache(category);
    } catch (_) {
      return _cacheService.getArticlesByCategory(category);
    }
  }

  Future<List<Article>> refreshCategory(String category) async {
    try {
      return await _crawlAndCache(category);
    } catch (_) {
      return _cacheService.getArticlesByCategory(category);
    }
  }

  Future<List<Article>> _crawlAndCache(String category) async {
    final urls = categoryUrls[category];
    if (urls == null) return [];

    final allArticles = <Article>[];
    final allErrors = <String>[];

    for (final entry in _crawlerServices.entries) {
      final sourceName = entry.key;
      final crawler = entry.value;
      final listingUrl = urls[sourceName];

      if (listingUrl == null) continue;

      final result = await crawler.crawlCategory(listingUrl, category);
      allArticles.addAll(result.articles);
      allErrors.addAll(result.errors);
    }

    // Errors are returned in CrawlResult for callers to handle

    if (allArticles.isNotEmpty) {
      await _cacheService.insertArticles(allArticles);
    }

    allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return allArticles;
  }
}
