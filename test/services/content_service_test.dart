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
  required DateTime publishedAt,
}) {
  return Article(
    id: id,
    title: 'Article $id',
    source: source,
    audioUrl: 'https://cdn.example.com/$id.mp3',
    articleUrl: 'https://example.com/$id',
    category: 'cong-nghe',
    publishedAt: publishedAt,
    cachedAt: DateTime.now(),
  );
}

void main() {
  late MockCacheService mockCache;
  late MockCrawlerService mockDantriCrawler;
  late MockCrawlerService mockSohaCrawler;
  late ContentService contentService;

  setUp(() {
    mockCache = MockCacheService();
    mockDantriCrawler = MockCrawlerService();
    mockSohaCrawler = MockCrawlerService();
    contentService = ContentService(
      cacheService: mockCache,
      crawlerServices: {
        'dantri': mockDantriCrawler,
        'soha': mockSohaCrawler,
      },
    );
  });

  group('getArticles', () {
    test('returns cached data when cache is fresh (no crawl triggered)', () async {
      mockCache.staleResult = false;
      mockCache.cachedArticles = [
        _buildArticle(id: '1', source: 'dantri', publishedAt: DateTime(2026, 6, 20)),
        _buildArticle(id: '2', source: 'soha', publishedAt: DateTime(2026, 6, 19)),
      ];

      final result = await contentService.getArticles('cong-nghe');

      expect(result.length, 2);
      expect(mockDantriCrawler.crawlCalled, false);
      expect(mockSohaCrawler.crawlCalled, false);
    });

    test('triggers crawl when cache is stale', () async {
      mockCache.staleResult = true;
      mockDantriCrawler.result = CrawlResult(
        articles: [
          _buildArticle(id: '1', source: 'dantri', publishedAt: DateTime(2026, 6, 20)),
        ],
        errors: [],
      );
      mockSohaCrawler.result = CrawlResult(
        articles: [
          _buildArticle(id: '2', source: 'soha', publishedAt: DateTime(2026, 6, 19)),
        ],
        errors: [],
      );

      final result = await contentService.getArticles('cong-nghe');

      expect(result.length, 2);
      expect(mockDantriCrawler.crawlCalled, true);
      expect(mockSohaCrawler.crawlCalled, true);
      expect(mockCache.insertedArticles.length, 2);
    });

    test('returns stale cache on crawl failure', () async {
      mockCache.staleResult = true;
      mockDantriCrawler.shouldThrow = true;
      mockSohaCrawler.shouldThrow = true;
      mockCache.cachedArticles = [
        _buildArticle(id: '1', source: 'dantri', publishedAt: DateTime(2026, 6, 18)),
      ];

      final result = await contentService.getArticles('cong-nghe');

      expect(result.length, 1);
      expect(result[0].id, '1');
    });

    test('returns empty list when crawl fails and no cache', () async {
      mockCache.staleResult = true;
      mockDantriCrawler.shouldThrow = true;
      mockSohaCrawler.shouldThrow = true;
      mockCache.cachedArticles = [];

      final result = await contentService.getArticles('cong-nghe');

      expect(result, isEmpty);
    });
  });

  group('refreshCategory', () {
    test('always crawls even when cache is fresh', () async {
      mockCache.staleResult = false;
      mockDantriCrawler.result = CrawlResult(
        articles: [
          _buildArticle(id: '1', source: 'dantri', publishedAt: DateTime(2026, 6, 20)),
        ],
        errors: [],
      );
      mockSohaCrawler.result = CrawlResult(articles: [], errors: []);

      final result = await contentService.refreshCategory('cong-nghe');

      expect(result.length, 1);
      expect(mockDantriCrawler.crawlCalled, true);
    });
  });

  group('multi-source', () {
    test('combines articles from both sources sorted by publishedAt DESC', () async {
      mockCache.staleResult = true;
      mockDantriCrawler.result = CrawlResult(
        articles: [
          _buildArticle(id: '1', source: 'dantri', publishedAt: DateTime(2026, 6, 18)),
          _buildArticle(id: '2', source: 'dantri', publishedAt: DateTime(2026, 6, 20)),
        ],
        errors: [],
      );
      mockSohaCrawler.result = CrawlResult(
        articles: [
          _buildArticle(id: '3', source: 'soha', publishedAt: DateTime(2026, 6, 19)),
        ],
        errors: [],
      );

      final result = await contentService.getArticles('cong-nghe');

      expect(result.length, 3);
      expect(result[0].id, '2'); // Jun 20
      expect(result[1].id, '3'); // Jun 19
      expect(result[2].id, '1'); // Jun 18
    });
  });

  group('init', () {
    test('calls cacheService init and clearExpired', () async {
      await contentService.init();

      expect(mockCache.initCalled, true);
      expect(mockCache.clearExpiredCalled, true);
    });
  });
}
