import 'package:flutter_test/flutter_test.dart';
import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/models/category_config.dart';
import 'package:news_playlist/services/cache_service_web.dart';

void main() {
  late CacheServiceWeb cache;

  setUp(() {
    cache = CacheServiceWeb();
  });

  group('CacheServiceWeb — isReady', () {
    test('is always true without calling init', () {
      expect(cache.isReady, true);
    });
  });

  group('CacheServiceWeb — init', () {
    test('completes without throwing', () async {
      await expectLater(cache.init(), completes);
    });

    test('calling init twice does not throw', () async {
      await cache.init();
      await expectLater(cache.init(), completes);
    });
  });

  group('CacheServiceWeb — articles', () {
    test('insertArticles completes without throwing', () async {
      final articles = [
        Article(
          id: 'web-1',
          title: 'Web Article',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/web-1.m4a',
          articleUrl: 'https://soha.vn/web-1.htm',
          category: 'soha_tech',
          publishedAt: DateTime(2026, 6, 29),
          cachedAt: DateTime.now(),
        ),
      ];
      await expectLater(cache.insertArticles(articles), completes);
    });

    test('insertArticles with empty list completes without throwing', () async {
      await expectLater(cache.insertArticles([]), completes);
    });

    test('getArticlesByCategory returns empty list', () async {
      final result = await cache.getArticlesByCategory('soha_tech');
      expect(result, isEmpty);
    });

    test('getArticlesByCategory returns articles after insert', () async {
      final articles = [
        Article(
          id: 'web-1',
          title: 'Web Article',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/web-1.m4a',
          articleUrl: 'https://soha.vn/web-1.htm',
          category: 'soha_tech',
          publishedAt: DateTime(2026, 6, 29),
          cachedAt: DateTime.now(),
        ),
      ];
      await cache.insertArticles(articles);
      final result = await cache.getArticlesByCategory('soha_tech');
      expect(result, hasLength(1));
      expect(result.first.id, 'web-1');
    });

    test('getArticleCount returns 0 for any category', () async {
      final count = await cache.getArticleCount('soha_tech');
      expect(count, 0);
    });

    test('getArticleCount returns count after insert', () async {
      final articles = [
        Article(
          id: 'web-1',
          title: 'Web Article',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/web-1.m4a',
          articleUrl: 'https://soha.vn/web-1.htm',
          category: 'soha_tech',
          publishedAt: DateTime(2026, 6, 29),
          cachedAt: DateTime.now(),
        ),
      ];
      await cache.insertArticles(articles);
      final count = await cache.getArticleCount('soha_tech');
      expect(count, 1);
    });
  });

  group('CacheServiceWeb — staleness', () {
    test('isStale always returns true', () async {
      final result = await cache.isStale('soha_tech');
      expect(result, true);
    });

    test('isStale returns true even after insert', () async {
      final articles = [
        Article(
          id: 'web-1',
          title: 'Web Article',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/web-1.m4a',
          articleUrl: 'https://soha.vn/web-1.htm',
          category: 'soha_tech',
          publishedAt: DateTime(2026, 6, 29),
          cachedAt: DateTime.now(),
        ),
      ];
      await cache.insertArticles(articles);
      final result = await cache.isStale('soha_tech');
      expect(result, true);
    });

    test('clearExpired completes without throwing', () async {
      await expectLater(cache.clearExpired(), completes);
    });

    test('clearAll completes without throwing', () async {
      await expectLater(cache.clearAll(), completes);
    });
  });

  group('CacheServiceWeb — categories', () {
    test('insertCategory completes without throwing', () async {
      const category = CategoryConfig(
        id: 'soha_test',
        name: 'Test',
        url: 'https://soha.vn/test.htm',
        source: 'soha',
      );
      await expectLater(cache.insertCategory(category), completes);
    });

    test('getCategories returns empty list', () async {
      final result = await cache.getCategories();
      expect(result, isEmpty);
    });

    test('getCategories returns categories after insert', () async {
      const category = CategoryConfig(
        id: 'soha_test',
        name: 'Test',
        url: 'https://soha.vn/test.htm',
        source: 'soha',
      );
      await cache.insertCategory(category);
      final result = await cache.getCategories();
      expect(result, hasLength(1));
      expect(result.first.id, 'soha_test');
    });

    test('deleteCategory completes without throwing', () async {
      await expectLater(cache.deleteCategory('nonexistent-id'), completes);
    });

    test('deleteCategory on existing id completes without throwing', () async {
      const category = CategoryConfig(
        id: 'soha_test',
        name: 'Test',
        url: 'https://soha.vn/test.htm',
        source: 'soha',
      );
      await cache.insertCategory(category);
      await expectLater(cache.deleteCategory('soha_test'), completes);
    });
  });

  group('CacheServiceWeb — playback state', () {
    test('savePlaybackState completes without throwing', () async {
      await expectLater(
        cache.savePlaybackState(
          category: 'soha_tech',
          articleIndex: 2,
          positionMs: 45000,
        ),
        completes,
      );
    });

    test('savePlaybackState with all optional fields completes without throwing',
        () async {
      await expectLater(
        cache.savePlaybackState(
          category: 'soha_tech',
          categoryUrl: 'https://soha.vn/tech.htm',
          articleIndex: 2,
          articleId: 'article-123',
          positionMs: 45000,
        ),
        completes,
      );
    });

    test('getPlaybackState returns null', () async {
      final result = await cache.getPlaybackState();
      expect(result, isNull);
    });

    test('getPlaybackState returns saved state after save', () async {
      await cache.savePlaybackState(
        category: 'soha_tech',
        articleIndex: 0,
        positionMs: 1000,
      );
      final result = await cache.getPlaybackState();
      expect(result, isNotNull);
      expect(result!['category'], 'soha_tech');
      expect(result['article_index'], 0);
      expect(result['position_ms'], 1000);
    });

    test('clearPlaybackState completes without throwing', () async {
      await expectLater(cache.clearPlaybackState(), completes);
    });
  });
}
