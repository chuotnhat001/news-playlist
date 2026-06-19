import 'dart:convert';

import 'package:html/parser.dart' as html_parser;

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/crawler_service.dart';

/// Crawler for soha.vn articles with audio.
class SohaCrawler implements SourceCrawler {
  static const categoryUrls = {
    'cong-nghe': 'https://soha.vn/cong-nghe.htm',
    'kinh-doanh': 'https://soha.vn/kinh-doanh.htm',
  };

  @override
  List<String> parseListingPage(String html) {
    final document = html_parser.parse(html);
    final urls = <String>[];
    final seen = <String>{};

    // Look for article links in listing containers
    final links = document.querySelectorAll(
      '.news-item a[href], .item-news a[href], article a[href], .list-news a[href]',
    );

    for (final link in links) {
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;

      // Build full URL
      final url = href.startsWith('http')
          ? href
          : 'https://soha.vn$href';

      // Filter for article URLs (contain .htm and numeric ID pattern)
      if (url.contains('.htm') && url.contains('soha.vn/') && !seen.contains(url)) {
        final path = Uri.tryParse(url)?.path ?? '';
        // Soha article URLs typically have a numeric suffix before .htm
        if (path.length > 5 && RegExp(r'\d+\.htm$').hasMatch(path)) {
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

    // Extract audio URL from embedTTS.init() JS block or <audio> fallback
    final audioUrl = _extractAudioUrl(html);
    if (audioUrl == null) return null;

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

    // Generate ID as deterministic hash of articleUrl
    final id = _generateId(articleUrl);

    return Article(
      id: id,
      title: title,
      source: 'soha',
      audioUrl: audioUrl,
      articleUrl: articleUrl,
      category: category,
      publishedAt: publishedAt,
      cachedAt: DateTime.now(),
    );
  }

  /// Extract audio URL from embedTTS.init() JS block or fallback to <audio> tag.
  String? _extractAudioUrl(String html) {
    // Primary: parse embedTTS.init() JavaScript block
    // Pattern: embedTTS.init({...newsId: "...", distributionDate: "...", nameSpace: "...", ext: "..."...})
    final ttsPattern = RegExp(
      r'embedTTS\.init\(\s*\{([^}]+)\}',
      multiLine: true,
    );
    final ttsMatch = ttsPattern.firstMatch(html);
    if (ttsMatch != null) {
      final block = ttsMatch.group(1) ?? '';
      final newsId = _extractJsField(block, 'newsId');
      final date = _extractJsField(block, 'distributionDate');
      final namespace = _extractJsField(block, 'nameSpace') ?? 'sohanews';
      final ext = _extractJsField(block, 'ext') ?? 'm4a';
      final voice = 'nu'; // Default to female Northern voice

      if (newsId != null && date != null) {
        return 'https://tts.mediacdn.vn/$date/$namespace-$voice-$newsId.$ext';
      }
    }

    // Fallback: look for <audio> element
    final audioPattern = RegExp(r'<(?:audio|source)[^>]+src="([^"]+)"');
    final audioMatch = audioPattern.firstMatch(html);
    if (audioMatch != null) {
      final src = audioMatch.group(1);
      if (src != null && src.isNotEmpty) {
        return src.startsWith('http') ? src : 'https://soha.vn$src';
      }
    }

    return null;
  }

  /// Extract a field value from a JS object literal string.
  String? _extractJsField(String block, String field) {
    final pattern = RegExp('${RegExp.escape(field)}\\s*:\\s*["\']([^"\']+)["\']');
    final match = pattern.firstMatch(block);
    return match?.group(1);
  }

  /// Generate a deterministic ID from a URL using simple hash.
  String _generateId(String url) {
    final bytes = utf8.encode(url);
    var hash = 0x811c9dc5; // FNV offset basis
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
