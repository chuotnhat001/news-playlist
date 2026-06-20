import 'dart:convert';

import 'package:html/parser.dart' as html_parser;

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/crawler_service.dart';

/// Crawler for dantri.com.vn articles with audio.
class DantriCrawler implements SourceCrawler {

  @override
  List<String> parseListingPage(String html) {
    final document = html_parser.parse(html);
    final urls = <String>[];
    final seen = <String>{};

    // Look for article links in listing containers
    final links = document.querySelectorAll('article a[href], .article-item a[href], .news-item a[href]');

    for (final link in links) {
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;

      // Build full URL
      final url = href.startsWith('http')
          ? href
          : 'https://dantri.com.vn$href';

      // Filter for article URLs (contain .htm and a path segment)
      if (url.contains('.htm') && url.contains('dantri.com.vn/') && !seen.contains(url)) {
        // Skip category pages (single segment like /kinh-doanh.htm)
        final path = Uri.tryParse(url)?.path ?? '';
        final segments = path.split('/').where((s) => s.isNotEmpty).toList();
        if (segments.length >= 2) {
          seen.add(url);
          urls.add(url);
        }
      }
    }

    return urls;
  }

  @override
  Article? parseArticlePage(String html, String articleUrl, String category) {
    final document = html_parser.parse(html);

    // Extract audio element
    final audioElement = document.querySelector('audio source[src], audio[src]');
    if (audioElement == null) return null;

    final audioSrc = audioElement.attributes['src'];
    if (audioSrc == null || audioSrc.isEmpty) return null;

    final audioUrl = audioSrc.startsWith('http')
        ? audioSrc
        : 'https://dantri.com.vn$audioSrc';

    // Extract title from h1
    final titleElement = document.querySelector('h1');
    if (titleElement == null) return null;
    final title = titleElement.text.trim();
    if (title.isEmpty) return null;

    // Extract published time
    final timeElement = document.querySelector('time[datetime]');
    DateTime publishedAt;
    if (timeElement != null) {
      final datetime = timeElement.attributes['datetime'] ?? '';
      publishedAt = DateTime.tryParse(datetime) ?? DateTime.now();
    } else {
      publishedAt = DateTime.now();
    }

    // Generate ID as md5-like hash of articleUrl
    final id = _generateId(articleUrl);

    return Article(
      id: id,
      title: title,
      source: 'dantri',
      audioUrl: audioUrl,
      articleUrl: articleUrl,
      category: category,
      publishedAt: publishedAt,
      cachedAt: DateTime.now(),
    );
  }

  /// Generate a deterministic ID from a URL using simple hash.
  String _generateId(String url) {
    final bytes = utf8.encode(url);
    // Simple hash using dart's hashCode for deterministic ID
    var hash = 0x811c9dc5; // FNV offset basis
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
