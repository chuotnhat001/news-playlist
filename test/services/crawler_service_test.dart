import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:news_playlist/services/crawler_service.dart';
import 'package:news_playlist/services/crawlers/dantri_crawler.dart';
import 'package:news_playlist/services/crawlers/soha_crawler.dart';

import 'crawler_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late String dantriListingHtml;
  late String dantriArticleHtml;
  late String dantriArticleNoAudioHtml;
  late String sohaListingHtml;
  late String sohaArticleHtml;

  setUpAll(() {
    dantriListingHtml =
        File('test/fixtures/dantri_listing.html').readAsStringSync();
    dantriArticleHtml =
        File('test/fixtures/dantri_article.html').readAsStringSync();
    dantriArticleNoAudioHtml =
        File('test/fixtures/dantri_article_no_audio.html').readAsStringSync();
    sohaListingHtml =
        File('test/fixtures/soha_listing.html').readAsStringSync();
    sohaArticleHtml =
        File('test/fixtures/soha_article.html').readAsStringSync();
  });

  group('DantriCrawler', () {
    late DantriCrawler crawler;

    setUp(() {
      crawler = DantriCrawler();
    });

    test('parseListingPage extracts correct article URLs', () {
      final urls = crawler.parseListingPage(dantriListingHtml);

      expect(urls, hasLength(5));
      expect(
        urls[0],
        'https://dantri.com.vn/suc-manh-so/trai-nghiem-iphone-16-pro-max-20241001123456789.htm',
      );
      expect(
        urls[1],
        'https://dantri.com.vn/suc-manh-so/ai-thay-doi-cuoc-song-20241002123456789.htm',
      );
      // All URLs should be absolute
      for (final url in urls) {
        expect(url, startsWith('https://dantri.com.vn/'));
        expect(url, endsWith('.htm'));
      }
    });

    test('parseArticlePage extracts title and audioUrl', () {
      final article = crawler.parseArticlePage(
        dantriArticleHtml,
        'https://dantri.com.vn/suc-manh-so/test-article.htm',
        'cong-nghe',
      );

      expect(article, isNotNull);
      expect(
        article!.title,
        'Trải nghiệm iPhone 16 Pro Max sau 1 tuần sử dụng',
      );
      expect(
        article.audioUrl,
        'https://cdn.dantri.com.vn/audio/2024/10/01/article-audio.mp3',
      );
      expect(article.source, 'dantri');
      expect(article.category, 'cong-nghe');
      expect(
        article.articleUrl,
        'https://dantri.com.vn/suc-manh-so/test-article.htm',
      );
      expect(article.id, isNotEmpty);
    });

    test('parseArticlePage returns null without audio element', () {
      final article = crawler.parseArticlePage(
        dantriArticleNoAudioHtml,
        'https://dantri.com.vn/suc-manh-so/no-audio.htm',
        'cong-nghe',
      );

      expect(article, isNull);
    });

    test('parseArticlePage generates deterministic ID', () {
      const url = 'https://dantri.com.vn/suc-manh-so/test.htm';
      final article1 = crawler.parseArticlePage(dantriArticleHtml, url, 'cong-nghe');
      final article2 = crawler.parseArticlePage(dantriArticleHtml, url, 'cong-nghe');

      expect(article1!.id, article2!.id);
    });
  });

  group('SohaCrawler', () {
    late SohaCrawler crawler;

    setUp(() {
      crawler = SohaCrawler();
    });

    test('parseListingPage extracts correct article URLs', () {
      final urls = crawler.parseListingPage(sohaListingHtml);

      expect(urls, hasLength(5));
      expect(
        urls[0],
        'https://soha.vn/cong-nghe-thay-doi-the-gioi-20241101123456789.htm',
      );
      // All URLs should be absolute
      for (final url in urls) {
        expect(url, startsWith('https://soha.vn/'));
        expect(url, endsWith('.htm'));
      }
    });

    test('parseArticlePage extracts title and audioUrl from embedTTS', () {
      final article = crawler.parseArticlePage(
        sohaArticleHtml,
        'https://soha.vn/test-article-123456789.htm',
        'cong-nghe',
      );

      expect(article, isNotNull);
      expect(
        article!.title,
        'Công nghệ AI đang thay đổi thế giới như thế nào',
      );
      expect(
        article.audioUrl,
        'https://tts.mediacdn.vn/2024/11/01/sohanews-nu-198241101100000123.m4a',
      );
      expect(article.source, 'soha');
      expect(article.category, 'cong-nghe');
      expect(article.id, isNotEmpty);
    });

    test('parseArticlePage returns null without audio element', () {
      final article = crawler.parseArticlePage(
        dantriArticleNoAudioHtml,
        'https://soha.vn/no-audio-123456789.htm',
        'cong-nghe',
      );

      expect(article, isNull);
    });
  });

  group('CrawlerService', () {
    late MockDio mockDio;
    late DantriCrawler crawler;
    late CrawlerService service;

    setUp(() {
      mockDio = MockDio();
      crawler = DantriCrawler();
      service = CrawlerService(crawler: crawler, dio: mockDio);
    });

    test('crawlCategory returns CrawlResult with articles', () async {
      // Mock listing page response
      when(mockDio.get<String>(any)).thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as String;
        if (url.contains('suc-manh-so.htm')) {
          return Response<String>(
            data: dantriListingHtml,
            statusCode: 200,
            requestOptions: RequestOptions(path: url),
          );
        }
        // Return article page for individual articles
        return Response<String>(
          data: dantriArticleHtml,
          statusCode: 200,
          requestOptions: RequestOptions(path: url),
        );
      });

      // Mock HEAD request for audio URL validation
      when(mockDio.head(any)).thenAnswer((invocation) async {
        return Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: invocation.positionalArguments[0] as String),
        );
      });

      final result = await service.crawlCategory(
        'https://dantri.com.vn/suc-manh-so.htm',
        'cong-nghe',
      );

      expect(result.successCount, 5);
      expect(result.hasErrors, isFalse);
      expect(result.articles, hasLength(5));
      for (final article in result.articles) {
        expect(article.source, 'dantri');
        expect(article.category, 'cong-nghe');
        expect(article.audioUrl, isNotEmpty);
      }
    });

    test('crawlCategory handles fetch errors gracefully', () async {
      when(mockDio.get<String>(any)).thenAnswer((invocation) async {
        final url = invocation.positionalArguments[0] as String;
        if (url.contains('suc-manh-so.htm')) {
          return Response<String>(
            data: dantriListingHtml,
            statusCode: 200,
            requestOptions: RequestOptions(path: url),
          );
        }
        // Simulate network error for article pages
        throw DioException(
          requestOptions: RequestOptions(path: url),
          message: 'Connection timeout',
        );
      });

      final result = await service.crawlCategory(
        'https://dantri.com.vn/suc-manh-so.htm',
        'cong-nghe',
      );

      expect(result.successCount, 0);
      expect(result.hasErrors, isTrue);
      expect(result.errors, hasLength(5));
    });

    test('crawlCategory returns error when listing page fails', () async {
      when(mockDio.get<String>(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Server error',
        ),
      );

      final result = await service.crawlCategory(
        'https://dantri.com.vn/suc-manh-so.htm',
        'cong-nghe',
      );

      expect(result.successCount, 0);
      expect(result.hasErrors, isTrue);
      expect(result.errors.first, contains('Failed to fetch listing page'));
    });
  });
}
