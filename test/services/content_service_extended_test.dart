import 'package:flutter_test/flutter_test.dart';
import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/cache_service.dart';
import 'package:news_playlist/services/content_service.dart';
import 'package:news_playlist/services/crawler_service.dart';

class MockCacheService extends CacheService {
  bool staleResult = true;
  List<Article> cachedArticles = [];
  List<Article> insertedArticles = [];
  bool initCalled = false;
  bool clearExpiredCalled = false;

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<bool> isStale(String category) async => staleResult;

  @override
  Future<List<Article>> getArticlesByCategory(String category) async =>
      cachedArticles;

  @override
  Future<void> insertArticles(List<Article> articles) async {
    insertedArticles = articles;
  }

  @override
  Future<void> clearExpired() async {
    clearExpiredCalled = true;
  }
}

class MockCrawlerService implements CrawlerService {
  CrawlResult? result;
  bool shouldThrow = false;
  bool crawlCalled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<CrawlResult> crawlCategory(String listingUrl, String category) async {
    crawlCalled = true;
    if (shouldThrow) throw Exception('Crawl failed');
    return result ?? CrawlResult(articles: [], errors: []);
  }
}

Article _buildArticle({
  required String id,
  required String source,
  required String category,
  required DateTime publishedAt,
}) {
  return Article(
    id: id,
    title: 'Article $id',
    source: source,
    audioUrl: 'https://cdn.example.com/$id.mp3',
    articleUrl: 'https://example.com/$id',
    category: category,
    publishedAt: publishedAt,
    cachedAt: DateTime.now(),
  );
}

void main() {
  late MockCacheService mockCache;
  late MockCrawlerService mockSohaCrawler;
  late ContentService contentService;

  setUp(() {
    mockCache = MockCacheService();
    mockSohaCrawler = MockCrawlerService();
    contentService = ContentService(
      cacheService: mockCache,
      crawlerServices: {'soha': mockSohaCrawler},
    );
  });

  group('getArticlesFromUrl', () {
    test('returns cached data when cache is fresh', () async {
      mockCache.staleResult = false;
      mockCache.cachedArticles = [
        _buildArticle(id: '1', source: 'soha', category: 'custom-cat', publishedAt: DateTime(2026, 6, 20)),
      ];

      final result = await contentService.getArticlesFromUrl(
        'https://soha.vn/custom.htm',
        'custom-cat',
      );

      expect(result.length, 1);
      expect(mockSohaCrawler.crawlCalled, false);
    });

    test('returns stale cache immediately via stale-while-revalidate', () async {
      mockCache.staleResult = true;
      mockCache.cachedArticles = [
        _buildArticle(id: '1', source: 'soha', category: 'custom-cat', publishedAt: DateTime(2026, 6, 18)),
      ];
      mockSohaCrawler.result = CrawlResult(
        articles: [
          _buildArticle(id: '2', source: 'soha', category: 'custom-cat', publishedAt: DateTime(2026, 6, 20)),
        ],
        errors: [],
      );

      final result = await contentService.getArticlesFromUrl(
        'https://soha.vn/custom.htm',
        'custom-cat',
      );

      // Returns stale cache immediately
      expect(result.length, 1);
      expect(result[0].id, '1');
      // Background crawl was triggered (fire-and-forget)
      await Future.delayed(const Duration(milliseconds: 10));
      expect(mockSohaCrawler.crawlCalled, true);
    });

    test('crawls synchronously when no cache exists', () async {
      mockCache.staleResult = true;
      mockCache.cachedArticles = [];
      mockSohaCrawler.result = CrawlResult(
        articles: [
          _buildArticle(id: '1', source: 'soha', category: 'custom-cat', publishedAt: DateTime(2026, 6, 20)),
        ],
        errors: [],
      );

      final result = await contentService.getArticlesFromUrl(
        'https://soha.vn/custom.htm',
        'custom-cat',
      );

      expect(result.length, 1);
      expect(result[0].id, '1');
      expect(mockSohaCrawler.crawlCalled, true);
    });

    test('returns empty list when no cache and crawl fails', () async {
      mockCache.staleResult = true;
      mockCache.cachedArticles = [];
      mockSohaCrawler.shouldThrow = true;

      final result = await contentService.getArticlesFromUrl(
        'https://soha.vn/custom.htm',
        'custom-cat',
      );

      expect(result, isEmpty);
    });
  });

  group('refreshUrl', () {
    test('always crawls even when cache is fresh', () async {
      mockCache.staleResult = false;
      mockSohaCrawler.result = CrawlResult(
        articles: [
          _buildArticle(id: '1', source: 'soha', category: 'custom-cat', publishedAt: DateTime(2026, 6, 20)),
        ],
        errors: [],
      );

      final result = await contentService.refreshUrl(
        'https://soha.vn/custom.htm',
        'custom-cat',
      );

      expect(result.length, 1);
      expect(mockSohaCrawler.crawlCalled, true);
    });

    test('falls back to cache on crawl failure', () async {
      mockCache.staleResult = false;
      mockSohaCrawler.shouldThrow = true;
      mockCache.cachedArticles = [
        _buildArticle(id: '1', source: 'soha', category: 'custom-cat', publishedAt: DateTime(2026, 6, 18)),
      ];

      final result = await contentService.refreshUrl(
        'https://soha.vn/custom.htm',
        'custom-cat',
      );

      expect(result.length, 1);
      expect(result[0].id, '1');
    });
  });

  group('stale-while-revalidate', () {
    test('background crawl error does not crash', () async {
      mockCache.staleResult = true;
      mockCache.cachedArticles = [
        _buildArticle(id: '1', source: 'soha', category: 'cong-nghe', publishedAt: DateTime(2026, 6, 18)),
      ];
      mockSohaCrawler.shouldThrow = true;

      final result = await contentService.getArticles('cong-nghe');

      // Returns stale cache
      expect(result.length, 1);
      // Background crawl fails silently
      await Future.delayed(const Duration(milliseconds: 10));
      expect(mockSohaCrawler.crawlCalled, true);
    });
  });
}
