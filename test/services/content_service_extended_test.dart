import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/cache_service.dart';
import 'package:news_playlist/services/content_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late CacheService cacheService;
  late ContentService contentService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    cacheService = CacheService();
    await cacheService.init();
    await cacheService.clearAll();
    await cacheService.clearPlaybackState();

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    contentService = ContentService(
      cacheService: cacheService,
      dio: dio,
    );
  });

  group('getArticlesFromUrl', () {
    test('returns cached data when cache is fresh', () async {
      final articles = [
        Article(
          id: '1',
          title: 'Article 1',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/1.m4a',
          articleUrl: 'https://soha.vn/1.htm',
          category: 'custom-cat',
          publishedAt: DateTime(2026, 6, 20),
          cachedAt: DateTime.now(),
        ),
      ];
      await cacheService.insertArticles(articles);

      final result = await contentService.getArticlesFromUrl(
        'https://soha.vn/custom.htm',
        'custom-cat',
      );

      expect(result.length, 1);
      expect(result[0].id, '1');
    });
  });

  group('refreshUrl', () {
    test('calls API and falls back to cache on failure', () async {
      final articles = [
        Article(
          id: '1',
          title: 'Cached Article',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/1.m4a',
          articleUrl: 'https://soha.vn/1.htm',
          category: 'custom-cat',
          publishedAt: DateTime(2026, 6, 18),
          cachedAt: DateTime.now(),
        ),
      ];
      await cacheService.insertArticles(articles);

      // refreshUrl with invalid API will timeout then fallback to cache
      // Use very short timeout Dio to make test fast
      final fastDio = Dio(BaseOptions(
        connectTimeout: const Duration(milliseconds: 100),
        receiveTimeout: const Duration(milliseconds: 100),
      ));
      final fastService = ContentService(
        cacheService: cacheService,
        dio: fastDio,
      );

      final result = await fastService.refreshUrl(
        'https://soha.vn/custom.htm',
        'custom-cat',
      );

      expect(result.length, 1);
      expect(result[0].title, 'Cached Article');
    });
  });

  group('getDiagnostic', () {
    test('returns null initially', () {
      expect(contentService.getDiagnostic('any-category'), isNull);
    });
  });
}
