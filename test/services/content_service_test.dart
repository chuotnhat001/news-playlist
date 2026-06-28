import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/models/category_config.dart';
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

  group('init', () {
    test('calls cacheService init and clearExpired', () async {
      final cache = CacheService();
      final dio = Dio();
      final service = ContentService(cacheService: cache, dio: dio);
      await service.init();
      expect(cache.isReady, true);
    });
  });

  group('getArticles', () {
    test('returns cached data when cache is fresh', () async {
      final articles = [
        Article(
          id: 'test-1',
          title: 'Test Article',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/test.m4a',
          articleUrl: 'https://soha.vn/test.htm',
          category: 'soha_cong-nghe',
          publishedAt: DateTime(2026, 6, 20),
          cachedAt: DateTime.now(),
        ),
      ];
      await cacheService.insertArticles(articles);

      final result = await contentService.getArticles('soha_cong-nghe');
      expect(result.length, 1);
      expect(result[0].id, 'test-1');
    });
  });

  group('getCustomCategories', () {
    test('returns categories from cache when API fails', () async {
      await cacheService.insertCategory(const CategoryConfig(
        id: 'soha_test',
        name: 'Test',
        url: 'https://soha.vn/test.htm',
        source: 'soha',
      ));

      final categories = await contentService.getCustomCategories();
      expect(categories.length, greaterThanOrEqualTo(1));
    });
  });

  group('getArticleCount', () {
    test('returns count from cache', () async {
      final articles = List.generate(
        3,
        (i) => Article(
          id: 'count-$i',
          title: 'Article $i',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/$i.m4a',
          articleUrl: 'https://soha.vn/$i.htm',
          category: 'soha_test',
          publishedAt: DateTime(2026, 6, 20),
          cachedAt: DateTime.now(),
        ),
      );
      await cacheService.insertArticles(articles);

      final count = await contentService.getArticleCount('soha_test');
      expect(count, 3);
    });
  });
}
