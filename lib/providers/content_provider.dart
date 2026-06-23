import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/cache_service.dart';
import 'package:news_playlist/services/content_service.dart';
import 'package:news_playlist/services/crawler_service.dart';
import 'package:news_playlist/services/crawlers/dantri_crawler.dart';
import 'package:news_playlist/services/crawlers/soha_crawler.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

final contentServiceProvider = Provider<ContentService>((ref) {
  final cacheService = ref.read(cacheServiceProvider);
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'User-Agent': 'NewsPlaylist/1.0',
    },
  ));

  final crawlerServices = <String, CrawlerService>{
    'dantri': CrawlerService(crawler: DantriCrawler(), dio: dio),
    'soha': CrawlerService(crawler: SohaCrawler(), dio: dio),
  };

  final service = ContentService(
    cacheService: cacheService,
    crawlerServices: crawlerServices,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final categoriesProvider = Provider<List<String>>((ref) {
  return ContentService.categoryUrls.keys.toList();
});

final articlesProvider =
    FutureProvider.family<List<Article>, String>((ref, category) async {
  final contentService = ref.read(contentServiceProvider);

  // Auto-refresh when background crawl completes for this category
  final sub = contentService.onBackgroundRefresh
      .where((id) => id == category)
      .listen((_) => ref.invalidateSelf());
  ref.onDispose(() => sub.cancel());

  return contentService.getArticles(category);
});

final articlesFromUrlProvider = FutureProvider.family<List<Article>,
    ({String url, String categoryId})>((ref, params) async {
  final contentService = ref.read(contentServiceProvider);

  // Auto-refresh when background crawl completes for this category
  final sub = contentService.onBackgroundRefresh
      .where((id) => id == params.categoryId)
      .listen((_) => ref.invalidateSelf());
  ref.onDispose(() => sub.cancel());

  return contentService.getArticlesFromUrl(params.url, params.categoryId);
});
