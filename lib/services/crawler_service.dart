import 'package:dio/dio.dart';

import 'package:news_playlist/models/article.dart';

/// Abstract interface for source-specific HTML parsers.
abstract class SourceCrawler {
  /// Parse a listing page HTML and return article URLs found.
  List<String> parseListingPage(String html);

  /// Parse an article page HTML and return an Article, or null if
  /// the article doesn't have audio content.
  Article? parseArticlePage(String html, String articleUrl, String category);
}

/// Result of a crawl operation containing articles and any errors.
class CrawlResult {
  final List<Article> articles;
  final List<String> errors;

  const CrawlResult({required this.articles, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
  int get successCount => articles.length;
}

/// Service that orchestrates crawling using a SourceCrawler and Dio.
class CrawlerService {
  final SourceCrawler crawler;
  final Dio dio;

  CrawlerService({required this.crawler, required this.dio});

  /// Crawl a category listing page and fetch individual articles.
  /// Returns a CrawlResult with successfully parsed articles and errors.
  Future<CrawlResult> crawlCategory(
    String listingUrl,
    String category,
  ) async {
    final articles = <Article>[];
    final errors = <String>[];

    // Fetch listing page
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

    // Parse article URLs from listing
    final articleUrls = crawler.parseListingPage(listingHtml);
    final urlsToFetch = articleUrls.take(10).toList();

    // Fetch each article with delay
    for (final url in urlsToFetch) {
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final response = await dio.get<String>(url);
        final html = response.data ?? '';
        final article = crawler.parseArticlePage(html, url, category);
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
