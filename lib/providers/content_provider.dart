import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/cache_service.dart';
import 'package:news_playlist/services/content_service.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

final contentServiceProvider = Provider<ContentService>((ref) {
  final cacheService = ref.read(cacheServiceProvider);
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'User-Agent': 'NewsPlaylist/1.0',
    },
  ));

  final service = ContentService(
    cacheService: cacheService,
    dio: dio,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final articlesProvider =
    FutureProvider.family<List<Article>, String>((ref, category) async {
  final contentService = ref.read(contentServiceProvider);
  return contentService.getArticles(category);
});

final articlesFromUrlProvider = FutureProvider.family<List<Article>,
    ({String url, String categoryId})>((ref, params) async {
  final contentService = ref.read(contentServiceProvider);
  return contentService.getArticlesFromUrl(params.url, params.categoryId);
});
