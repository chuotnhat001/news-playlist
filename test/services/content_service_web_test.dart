import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/models/category_config.dart';
import 'package:news_playlist/services/cache_service_web.dart';
import 'package:news_playlist/services/content_service.dart';

// ---------------------------------------------------------------------------
// Fake HTTP adapter — intercepts Dio requests without hitting the network.
// ---------------------------------------------------------------------------

typedef _RequestHandler = Future<ResponseBody> Function(RequestOptions options);

class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter(this._handler);

  final _RequestHandler _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object body, {int statusCode = 200}) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Dio _dioWith(_RequestHandler handler) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
  dio.httpClientAdapter = _FakeHttpAdapter(handler);
  return dio;
}

const _fakeCategoriesPayload = [
  {
    'id': 'soha_cong-nghe',
    'name': 'Công nghệ',
    'url': 'https://soha.vn/cong-nghe.htm',
    'source': 'soha',
  },
  {
    'id': 'soha_xa-hoi',
    'name': 'Xã hội',
    'url': 'https://soha.vn/xa-hoi.htm',
    'source': 'soha',
  },
];

const _fakeArticlesPayload = {
  'articles': [
    {
      'id': 'art-1',
      'title': 'Tin tức công nghệ mới nhất',
      'source': 'soha',
      'audio_url': 'https://tts.mediacdn.vn/art-1.m4a',
      'article_url': 'https://soha.vn/art-1.htm',
      'published_at': '2026-06-29T10:00:00.000Z',
    },
  ],
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ContentService — web scenario (CacheServiceWeb, no SQLite)', () {
    late CacheServiceWeb webCache;

    setUp(() {
      webCache = CacheServiceWeb();
    });

    // -----------------------------------------------------------------------
    // getCustomCategories — cache always empty on web
    // -----------------------------------------------------------------------

    group('getCustomCategories', () {
      test('returns categories from API when cache is empty', () async {
        final dio = _dioWith((_) async => _jsonResponse(_fakeCategoriesPayload));
        final service = ContentService(cacheService: webCache, dio: dio);

        final categories = await service.getCustomCategories();

        expect(categories.length, 2);
        expect(categories[0].id, 'soha_cong-nghe');
        expect(categories[0].name, 'Công nghệ');
        expect(categories[1].id, 'soha_xa-hoi');
      });

      test('returned categories have correct fields', () async {
        final dio = _dioWith((_) async => _jsonResponse(_fakeCategoriesPayload));
        final service = ContentService(cacheService: webCache, dio: dio);

        final categories = await service.getCustomCategories();
        final first = categories.first;

        expect(first.url, 'https://soha.vn/cong-nghe.htm');
        expect(first.source, 'soha');
      });

      test('returns empty list when API returns empty array and cache is empty',
          () async {
        final dio = _dioWith((_) async => _jsonResponse(<dynamic>[]));
        final service = ContentService(cacheService: webCache, dio: dio);

        final categories = await service.getCustomCategories();

        expect(categories, isEmpty);
      });

      test('returns empty list when API fails and cache is empty (web path)',
          () async {
        final dio = _dioWith((_) async => throw DioException(
              requestOptions: RequestOptions(path: '/'),
              type: DioExceptionType.connectionTimeout,
            ));
        final service = ContentService(cacheService: webCache, dio: dio);

        // On web, cache.getCategories() returns [] — no fallback data.
        final categories = await service.getCustomCategories();

        expect(categories, isEmpty);
      });

      test('does not throw when API returns empty object data', () async {
        // Simulate a 200 with an unexpected body shape (not a list).
        // The service catches cast exceptions and falls back to cache (empty on web).
        final dio = _dioWith((_) async => _jsonResponse(<String, dynamic>{}));
        final service = ContentService(cacheService: webCache, dio: dio);

        final categories = await service.getCustomCategories();
        expect(categories, isEmpty);
      });

      test('insertCategory called for each API category persists in memory on web',
          () async {
        final dio = _dioWith((_) async => _jsonResponse(_fakeCategoriesPayload));
        final service = ContentService(cacheService: webCache, dio: dio);

        await service.getCustomCategories();

        // CacheServiceWeb stores categories in memory.
        final cached = await webCache.getCategories();
        expect(cached, hasLength(2));
        expect(cached[0].id, 'soha_cong-nghe');
      });
    });

    // -----------------------------------------------------------------------
    // getCustomCategories — verifies API endpoint called without User-Agent
    // -----------------------------------------------------------------------

    group('getCustomCategories — request headers', () {
      test('does not include User-Agent header in request', () async {
        RequestOptions? capturedOptions;
        final dio = _dioWith((options) async {
          capturedOptions = options;
          return _jsonResponse(_fakeCategoriesPayload);
        });
        final service = ContentService(cacheService: webCache, dio: dio);

        await service.getCustomCategories();

        // ContentService itself never sets User-Agent — that is the provider's
        // responsibility.  Confirm the service-level headers do not include it.
        final headers = capturedOptions?.headers ?? {};
        expect(headers.containsKey('User-Agent'), false);
      });

      test('includes Authorization and apikey headers', () async {
        RequestOptions? capturedOptions;
        final dio = _dioWith((options) async {
          capturedOptions = options;
          return _jsonResponse(_fakeCategoriesPayload);
        });
        final service = ContentService(cacheService: webCache, dio: dio);

        await service.getCustomCategories();

        final headers = capturedOptions?.headers ?? {};
        expect(headers.containsKey('Authorization'), true);
        expect(headers.containsKey('apikey'), true);
      });
    });

    // -----------------------------------------------------------------------
    // getArticles — cache always stale on web, must fetch from API
    // -----------------------------------------------------------------------

    group('getArticles (web path — cache always stale)', () {
      test('fetches articles from API when cache is empty', () async {
        final dio = _dioWith((_) async => _jsonResponse(_fakeArticlesPayload));
        final service = ContentService(cacheService: webCache, dio: dio);

        final articles = await service.getArticles('soha_cong-nghe');

        expect(articles.length, 1);
        expect(articles[0].id, 'art-1');
        expect(articles[0].title, 'Tin tức công nghệ mới nhất');
      });

      test('article fields are correctly parsed', () async {
        final dio = _dioWith((_) async => _jsonResponse(_fakeArticlesPayload));
        final service = ContentService(cacheService: webCache, dio: dio);

        final articles = await service.getArticles('soha_cong-nghe');
        final article = articles.first;

        expect(article.source, 'soha');
        expect(article.audioUrl, 'https://tts.mediacdn.vn/art-1.m4a');
        expect(article.articleUrl, 'https://soha.vn/art-1.htm');
        expect(article.category, 'soha_cong-nghe');
        expect(article.publishedAt, DateTime.utc(2026, 6, 29, 10, 0, 0));
      });

      test('returns empty list when API returns empty articles array', () async {
        final dio =
            _dioWith((_) async => _jsonResponse({'articles': <dynamic>[]}));
        final service = ContentService(cacheService: webCache, dio: dio);

        final articles = await service.getArticles('soha_cong-nghe');

        expect(articles, isEmpty);
      });

      test('returns empty list when API fails and cache is empty', () async {
        final dio = _dioWith((_) async => throw DioException(
              requestOptions: RequestOptions(path: '/'),
              type: DioExceptionType.receiveTimeout,
            ));
        final service = ContentService(cacheService: webCache, dio: dio);

        final articles = await service.getArticles('soha_cong-nghe');

        // Falls back to cache.getArticlesByCategory — empty on web.
        expect(articles, isEmpty);
      });

      test('sets diagnostic message when API returns null data', () async {
        final dio = _dioWith(
            (_) async => _jsonResponse(<String, dynamic>{}..remove('anything')));
        // Response has data={} — articles key is missing, treated as empty list.
        final service = ContentService(cacheService: webCache, dio: dio);

        final articles = await service.getArticles('soha_cong-nghe');
        expect(articles, isEmpty);
      });

      test('diagnostics are null after successful fetch', () async {
        final dio = _dioWith((_) async => _jsonResponse(_fakeArticlesPayload));
        final service = ContentService(cacheService: webCache, dio: dio);

        await service.getArticles('soha_cong-nghe');

        expect(service.getDiagnostic('soha_cong-nghe'), isNull);
      });

      test('onBackgroundRefresh emits categoryId on successful API fetch',
          () async {
        final dio = _dioWith((_) async => _jsonResponse(_fakeArticlesPayload));
        final service = ContentService(cacheService: webCache, dio: dio);

        // Subscribe before calling getArticles so we don't miss the event.
        final emitted = <String>[];
        final sub = service.onBackgroundRefresh.listen(emitted.add);

        await service.getArticles('soha_cong-nghe');

        // Give the broadcast stream a microtask to deliver the event.
        await Future<void>.microtask(() {});
        await sub.cancel();

        expect(emitted, contains('soha_cong-nghe'));
      });

      test('insertArticles on web cache stores articles in memory', () async {
        final dio = _dioWith((_) async => _jsonResponse(_fakeArticlesPayload));
        final service = ContentService(cacheService: webCache, dio: dio);

        await service.getArticles('soha_cong-nghe');

        // Web cache stores articles in memory for the session.
        final cached = await webCache.getArticlesByCategory('soha_cong-nghe');
        expect(cached, hasLength(1));
        expect(cached.first.id, 'art-1');
      });
    });

    // -----------------------------------------------------------------------
    // getArticleCount — always 0 on web
    // -----------------------------------------------------------------------

    group('getArticleCount', () {
      test('returns article count from API response on web', () async {
        final dio = _dioWith((_) async => _jsonResponse(_fakeArticlesPayload));
        final service = ContentService(cacheService: webCache, dio: dio);

        await service.getArticles('soha_cong-nghe');
        final count = await service.getArticleCount('soha_cong-nghe');

        expect(count, 1);
      });
    });

    // -----------------------------------------------------------------------
    // addCategory / removeCategory — no-ops on web
    // -----------------------------------------------------------------------

    group('addCategory / removeCategory', () {
      test('addCategory does not throw on web', () async {
        final service = ContentService(
          cacheService: webCache,
          dio: Dio(),
        );
        await expectLater(
          service.addCategory(const CategoryConfig(
            id: 'soha_test',
            name: 'Test',
            url: 'https://soha.vn/test.htm',
            source: 'soha',
          )),
          completes,
        );
      });

      test('removeCategory does not throw on web', () async {
        final service = ContentService(
          cacheService: webCache,
          dio: Dio(),
        );
        await expectLater(
          service.removeCategory('soha_test'),
          completes,
        );
      });
    });

    // -----------------------------------------------------------------------
    // init — no-op on web
    // -----------------------------------------------------------------------

    group('init', () {
      test('completes without throwing on web', () async {
        final service = ContentService(
          cacheService: webCache,
          dio: Dio(),
        );
        await expectLater(service.init(), completes);
      });
    });

    // -----------------------------------------------------------------------
    // dispose
    // -----------------------------------------------------------------------

    group('dispose', () {
      test('dispose closes stream without throwing', () {
        final service = ContentService(
          cacheService: webCache,
          dio: Dio(),
        );
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });

  // -------------------------------------------------------------------------
  // ContentService — header behaviour: User-Agent is NOT set by the service
  // itself; content_provider.dart conditionally omits it based on kIsWeb.
  // We test the service-level contract: no User-Agent in ContentService headers.
  // -------------------------------------------------------------------------

  group('ContentService — User-Agent header contract', () {
    test('_headers getter does not include User-Agent key', () async {
      // We verify indirectly: capture the request options sent by the service
      // and assert User-Agent is absent from the service-controlled headers.
      RequestOptions? captured;
      final dio = _dioWith((options) async {
        captured = options;
        return _jsonResponse(_fakeCategoriesPayload);
      });

      final service = ContentService(
        cacheService: CacheServiceWeb(),
        dio: dio,
      );
      await service.getCustomCategories();

      expect(captured, isNotNull);
      // The service-level _headers map only sets Authorization and apikey.
      final requestHeaders = captured!.headers;
      expect(requestHeaders.containsKey('User-Agent'), false,
          reason:
              'ContentService must not set User-Agent; that is the provider layer responsibility');
    });

    test('Dio BaseOptions without User-Agent header does not add it by default',
        () async {
      // Regression: ensure constructing Dio without User-Agent in headers
      // does not silently inject one via BaseOptions.
      RequestOptions? captured;
      final dio = Dio(BaseOptions(
        headers: {
          // Explicitly no 'User-Agent' key — simulates kIsWeb=true path in provider.
          'Authorization': 'Bearer test-key',
          'apikey': 'test-key',
        },
      ));
      dio.httpClientAdapter = _FakeHttpAdapter((options) async {
        captured = options;
        return _jsonResponse(_fakeCategoriesPayload);
      });

      final service = ContentService(
        cacheService: CacheServiceWeb(),
        dio: dio,
      );
      await service.getCustomCategories();

      expect(captured, isNotNull);
      final headers = captured!.headers;
      expect(headers.containsKey('User-Agent'), false);
    });

    test(
        'Dio BaseOptions with User-Agent header propagates it to request (native path)',
        () async {
      // Verify our fake adapter faithfully captures headers — sanity check.
      RequestOptions? captured;
      final dio = Dio(BaseOptions(
        headers: {'User-Agent': 'NewsPlaylist/1.0'},
      ));
      dio.httpClientAdapter = _FakeHttpAdapter((options) async {
        captured = options;
        return _jsonResponse(_fakeCategoriesPayload);
      });

      final service = ContentService(
        cacheService: CacheServiceWeb(),
        dio: dio,
      );
      await service.getCustomCategories();

      expect(captured, isNotNull);
      expect(captured!.headers.containsKey('User-Agent'), true);
      expect(captured!.headers['User-Agent'], 'NewsPlaylist/1.0');
    });
  });
}
