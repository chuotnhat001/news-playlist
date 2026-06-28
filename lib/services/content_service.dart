import 'dart:async';

import 'package:dio/dio.dart';

import '../models/article.dart';
import '../models/category_config.dart';
import 'cache_service.dart';

class ContentService {
  final CacheService _cacheService;
  final Dio _dio;

  static const _supabaseUrl = 'https://zkzpdsijcpnrzczmlpfk.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InprenBkc2lqY3Bucnpjem1scGZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NjI3NDMsImV4cCI6MjA5ODEzODc0M30.N87qUI5DRbjHfMkczOA0ZAn9iOFI3khuyfyudTlLTtc';

  final _refreshController = StreamController<String>.broadcast();
  Stream<String> get onBackgroundRefresh => _refreshController.stream;

  String? _lastDiagnostic;
  String? getDiagnostic(String categoryId) => _lastDiagnostic;

  ContentService({
    required CacheService cacheService,
    required Dio dio,
  })  : _cacheService = cacheService,
        _dio = dio;

  Future<void> init() async {
    await _cacheService.init();
    await _cacheService.clearExpired();
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_anonKey',
        'apikey': _anonKey,
      };

  Future<List<CategoryConfig>> getCustomCategories() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '$_supabaseUrl/functions/v1/refresh',
        options: Options(headers: _headers),
      );
      final data = response.data ?? [];
      final categories = data.map((json) {
        return CategoryConfig(
          id: json['id'] as String,
          name: json['name'] as String,
          url: json['url'] as String,
          source: json['source'] as String,
        );
      }).toList();

      for (final cat in categories) {
        await _cacheService.insertCategory(cat);
      }
      return categories;
    } catch (_) {
      return _cacheService.getCategories();
    }
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

  Future<List<Article>> getArticles(String categoryId) async {
    return _getArticlesFromApi(categoryId);
  }

  Future<List<Article>> getArticlesFromUrl(String url, String categoryId) async {
    return _getArticlesFromApi(categoryId);
  }

  Future<List<Article>> refreshCategory(String categoryId) async {
    return _getArticlesFromApi(categoryId, forceRefresh: true);
  }

  Future<List<Article>> refreshUrl(String url, String categoryId) async {
    return _getArticlesFromApi(categoryId, forceRefresh: true);
  }

  Future<List<Article>> _getArticlesFromApi(
    String categoryId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final stale = await _cacheService.isStale(categoryId);
      if (!stale) {
        final cached = await _cacheService.getArticlesByCategory(categoryId);
        if (cached.isNotEmpty) return cached;
      }
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_supabaseUrl/functions/v1/refresh',
        queryParameters: {'category_id': categoryId},
        options: Options(headers: _headers),
      );
      final data = response.data;
      if (data == null) {
        _lastDiagnostic = 'Không nhận được dữ liệu từ server';
        return [];
      }

      final articlesJson = data['articles'] as List<dynamic>? ?? [];
      if (articlesJson.isEmpty) {
        _lastDiagnostic = 'Server không có bài viết nào cho danh mục này.\nHãy đợi hệ thống cập nhật (mỗi 30 phút).';
        return _cacheService.getArticlesByCategory(categoryId);
      }

      _lastDiagnostic = null;
      final articles = articlesJson.map((json) {
        return Article(
          id: json['id'] as String,
          title: json['title'] as String,
          source: json['source'] as String,
          audioUrl: json['audio_url'] as String,
          articleUrl: json['article_url'] as String,
          category: categoryId,
          publishedAt: DateTime.parse(json['published_at'] as String),
          cachedAt: DateTime.now(),
        );
      }).toList();

      await _cacheService.insertArticles(articles);
      _refreshController.add(categoryId);
      return articles;
    } catch (e) {
      _lastDiagnostic = 'Lỗi kết nối server: $e';
      return _cacheService.getArticlesByCategory(categoryId);
    }
  }

  void dispose() {
    _refreshController.close();
  }
}
