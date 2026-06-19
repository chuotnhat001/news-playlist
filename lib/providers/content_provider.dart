import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/cache_service.dart';
import 'package:news_playlist/services/content_service.dart';
import 'package:news_playlist/services/crawler_service.dart';
import 'package:news_playlist/services/crawlers/dantri_crawler.dart';
import 'package:news_playlist/services/crawlers/soha_crawler.dart';

final contentServiceProvider = Provider<ContentService>((ref) {
  final cacheService = CacheService();
  final dio = Dio();

  final crawlerServices = <String, CrawlerService>{
    'dantri': CrawlerService(crawler: DantriCrawler(), dio: dio),
    'soha': CrawlerService(crawler: SohaCrawler(), dio: dio),
  };

  return ContentService(
    cacheService: cacheService,
    crawlerServices: crawlerServices,
  );
});

final categoriesProvider = Provider<List<String>>((ref) {
  return ContentService.categoryUrls.keys.toList();
});

final articlesProvider =
    FutureProvider.family<List<Article>, String>((ref, category) async {
  final contentService = ref.read(contentServiceProvider);
  return contentService.getArticles(category);
});
