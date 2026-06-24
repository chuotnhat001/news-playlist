import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:news_playlist/services/crawlers/soha_crawler.dart';
import 'package:news_playlist/services/crawler_service.dart';

void main() {
  late CrawlerService crawlerService;
  late Dio dio;

  setUpAll(() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'User-Agent': 'NewsPlaylist/1.0'},
    ));
    crawlerService = CrawlerService(crawler: SohaCrawler(), dio: dio);
  });

  tearDownAll(() {
    dio.close();
  });

  group('Soha.vn live crawl integration', () {
    test('crawl listing page returns article URLs', () async {
      final result = await crawlerService.crawlCategory(
        'https://soha.vn/cong-nghe.htm',
        'cong-nghe',
      );

      print('Articles found: ${result.articles.length}');
      print('Errors: ${result.errors.length}');
      for (final e in result.errors) {
        print('  Error: $e');
      }

      expect(result.articles, isNotEmpty,
          reason: 'Should find at least 1 article with audio');

      // Verify first article has valid audio URL
      final first = result.articles.first;
      print('First article: ${first.title}');
      print('Audio URL: ${first.audioUrl}');
      expect(first.audioUrl, startsWith('https://tts.mediacdn.vn'));
      expect(first.title, isNotEmpty);
    });

    test('audio URL is accessible (HTTP 200)', () async {
      final result = await crawlerService.crawlCategory(
        'https://soha.vn/cong-nghe.htm',
        'cong-nghe',
      );

      if (result.articles.isEmpty) {
        fail('No articles found to test audio URL');
      }

      final audioUrl = result.articles.first.audioUrl;
      print('Testing audio URL: $audioUrl');

      final response = await dio.head(audioUrl);
      print('HTTP status: ${response.statusCode}');
      print('Content-Type: ${response.headers.value("content-type")}');
      print('Content-Length: ${response.headers.value("content-length")}');

      expect(response.statusCode, 200);
    });
  });
}
