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

  const CrawlResult({required this.articles, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
  int get successCount => articles.length;
}

class CrawlerService {
  final SourceCrawler crawler;
  final Dio dio;

  CrawlerService({required this.crawler, required this.dio});

  Future<CrawlResult> crawlCategory(
    String listingUrl,
    String category,
  ) async {
    final articles = <Article>[];
    final errors = <String>[];

    final String listingHtml;
    try {
      final response = await dio.get<String>(listingUrl);
      listingHtml = response.data ?? '';
    } catch (e) {
      return CrawlResult(
        articles: [],
        errors: ['Failed to fetch listing page $listingUrl: $e'],
      );
    }

    // Parse listing in isolate to avoid jank
    final crawlerType = crawler.runtimeType.toString();
    final articleUrls = await compute(
      _parseListingIsolate,
      _ListingPayload(html: listingHtml, crawlerType: crawlerType),
    );
    final urlsToFetch = articleUrls.take(10).toList();

    for (final url in urlsToFetch) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final response = await dio.get<String>(url);
        final html = response.data ?? '';
        // Parse each article in isolate
        final article = await compute(
          _parseArticleIsolate,
          _ArticlePayload(
            html: html,
            articleUrl: url,
            category: category,
            crawlerType: crawlerType,
          ),
        );
        if (article != null) {
          articles.add(article);
        }
      } catch (e) {
        errors.add('Failed to fetch article $url: $e');
      }
    }

    return CrawlResult(articles: articles, errors: errors);
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
