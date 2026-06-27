import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/crawlers/dantri_crawler.dart';
import 'package:news_playlist/services/crawlers/soha_crawler.dart';

abstract class SourceCrawler {
  List<String> parseListingPage(String html);
  Article? parseArticlePage(String html, String articleUrl, String category);
}

class CrawlResult {
  final List<Article> articles;
  final List<String> errors;
  final int totalArticlesFound;
  final int noAudioCount;
  final int invalidUrlCount;

  const CrawlResult({
    required this.articles,
    required this.errors,
    this.totalArticlesFound = 0,
    this.noAudioCount = 0,
    this.invalidUrlCount = 0,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get successCount => articles.length;
}

class CrawlerService {
  final SourceCrawler crawler;
  final Dio dio;

  static const _allowedHosts = {
    'dantri.com.vn',
    'cdn.dantri.com.vn',
    'cdnimg.vietnamplus.vn',
    'tts.mediacdn.vn',
    'soha.vn',
    'cdn.soha.vn',
  };

  CrawlerService({required this.crawler, required this.dio});

  Future<CrawlResult> crawlCategory(
    String listingUrl,
    String category,
  ) async {
    final articles = <Article>[];
    final errors = <String>[];
    var noAudioCount = 0;
    var invalidUrlCount = 0;

    final String listingHtml;
    try {
      final response = await dio.get<String>(listingUrl);
      listingHtml = response.data ?? '';
    } catch (e) {
      return CrawlResult(
        articles: [],
        errors: ['Không thể tải trang danh mục: $e'],
      );
    }

    // Parse listing in isolate to avoid jank
    final crawlerType = crawler.runtimeType.toString();
    final articleUrls = await compute(
      _parseListingIsolate,
      _ListingPayload(html: listingHtml, crawlerType: crawlerType),
    );
    final urlsToFetch = articleUrls.take(10).toList();

    if (urlsToFetch.isEmpty) {
      return CrawlResult(
        articles: [],
        errors: ['Không tìm thấy bài viết nào trên trang'],
        totalArticlesFound: 0,
      );
    }

    for (final url in urlsToFetch) {
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        final response = await dio.get<String>(url);
        final html = response.data ?? '';
        final article = await compute(
          _parseArticleIsolate,
          _ArticlePayload(
            html: html,
            articleUrl: url,
            category: category,
            crawlerType: crawlerType,
          ),
        );
        if (article == null) {
          noAudioCount++;
        } else if (_isValidArticle(article)) {
          articles.add(article);
        } else {
          invalidUrlCount++;
          errors.add('URL không hợp lệ: ${article.audioUrl}');
        }
      } catch (e) {
        errors.add('Lỗi tải bài: $e');
      }
    }

    return CrawlResult(
      articles: articles,
      errors: errors,
      totalArticlesFound: urlsToFetch.length,
      noAudioCount: noAudioCount,
      invalidUrlCount: invalidUrlCount,
    );
  }

  static bool _isValidArticle(Article article) {
    return _isValidUrl(article.audioUrl) && _isValidUrl(article.articleUrl);
  }

  static bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme != 'https') return false;
    if (!_allowedHosts.any((host) => uri.host == host || uri.host.endsWith('.$host'))) {
      return false;
    }
    if (uri.path.contains('..')) return false;
    return true;
  }
}

class _ListingPayload {
  final String html;
  final String crawlerType;
  _ListingPayload({required this.html, required this.crawlerType});
}

class _ArticlePayload {
  final String html;
  final String articleUrl;
  final String category;
  final String crawlerType;
  _ArticlePayload({
    required this.html,
    required this.articleUrl,
    required this.category,
    required this.crawlerType,
  });
}

// Top-level functions for compute() — these run in a separate isolate
List<String> _parseListingIsolate(_ListingPayload payload) {
  final crawler = _createCrawler(payload.crawlerType);
  return crawler.parseListingPage(payload.html);
}

Article? _parseArticleIsolate(_ArticlePayload payload) {
  final crawler = _createCrawler(payload.crawlerType);
  return crawler.parseArticlePage(payload.html, payload.articleUrl, payload.category);
}

SourceCrawler _createCrawler(String type) {
  switch (type) {
    case 'DantriCrawler':
      return DantriCrawler();
    case 'SohaCrawler':
      return SohaCrawler();
    default:
      throw StateError('Unknown crawler type: $type');
  }
}
