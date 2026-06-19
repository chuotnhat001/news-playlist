import 'package:flutter_test/flutter_test.dart';
import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/cache_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late CacheService cacheService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    cacheService = CacheService();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await cacheService.initWithDatabase(db);
    await cacheService.clearAll();
  });

  Article makeArticle({
    required String id,
    required String category,
    String title = 'Test Article',
    DateTime? publishedAt,
    DateTime? cachedAt,
  }) {
    return Article(
      id: id,
      title: title,
      source: 'Test Source',
      audioUrl: 'https://example.com/audio.mp3',
      articleUrl: 'https://example.com/article',
      category: category,
      publishedAt: publishedAt ?? DateTime.now(),
      cachedAt: cachedAt ?? DateTime.now(),
    );
  }

  test('insert 3 articles (2 tech, 1 business), query tech returns 2', () async {
    final articles = [
      makeArticle(id: '1', category: 'tech'),
      makeArticle(id: '2', category: 'tech'),
      makeArticle(id: '3', category: 'business'),
    ];

    await cacheService.insertArticles(articles);
    final result = await cacheService.getArticlesByCategory('tech');

    expect(result.length, 2);
    expect(result.every((a) => a.category == 'tech'), true);
  });

  test('query non-existent category returns empty', () async {
    final articles = [
      makeArticle(id: '1', category: 'tech'),
    ];

    await cacheService.insertArticles(articles);
    final result = await cacheService.getArticlesByCategory('sports');

    expect(result, isEmpty);
  });

  test('article with cachedAt 7h ago is excluded (stale)', () async {
    final staleTime = DateTime.now().subtract(const Duration(hours: 7));
    final articles = [
      makeArticle(id: '1', category: 'tech', cachedAt: staleTime),
    ];

    await cacheService.insertArticles(articles);
    final result = await cacheService.getArticlesByCategory('tech');

    expect(result, isEmpty);
  });

  test('article with cachedAt 5h ago is included (fresh)', () async {
    final freshTime = DateTime.now().subtract(const Duration(hours: 5));
    final articles = [
      makeArticle(id: '1', category: 'tech', cachedAt: freshTime),
    ];

    await cacheService.insertArticles(articles);
    final result = await cacheService.getArticlesByCategory('tech');

    expect(result.length, 1);
  });

  test('isStale returns true for empty category', () async {
    final result = await cacheService.isStale('nonexistent');
    expect(result, true);
  });

  test('isStale returns false when fresh articles exist', () async {
    final articles = [
      makeArticle(id: '1', category: 'tech'),
    ];

    await cacheService.insertArticles(articles);
    final result = await cacheService.isStale('tech');

    expect(result, false);
  });

  test('clearExpired removes stale, keeps fresh', () async {
    final staleTime = DateTime.now().subtract(const Duration(hours: 7));
    final freshTime = DateTime.now().subtract(const Duration(hours: 5));

    final articles = [
      makeArticle(id: '1', category: 'tech', cachedAt: staleTime),
      makeArticle(id: '2', category: 'tech', cachedAt: freshTime),
    ];

    await cacheService.insertArticles(articles);
    await cacheService.clearExpired();

    final result = await cacheService.getArticlesByCategory('tech');
    expect(result.length, 1);
    expect(result.first.id, '2');
  });

  test('upsert: same ID with different title is updated', () async {
    final original = makeArticle(id: '1', category: 'tech', title: 'Original');
    final updated = makeArticle(id: '1', category: 'tech', title: 'Updated');

    await cacheService.insertArticles([original]);
    await cacheService.insertArticles([updated]);

    final result = await cacheService.getArticlesByCategory('tech');
    expect(result.length, 1);
    expect(result.first.title, 'Updated');
  });

  test('results ordered by publishedAt DESC', () async {
    final now = DateTime.now();
    final articles = [
      makeArticle(
        id: '1',
        category: 'tech',
        publishedAt: now.subtract(const Duration(hours: 2)),
      ),
      makeArticle(
        id: '2',
        category: 'tech',
        publishedAt: now.subtract(const Duration(hours: 1)),
      ),
      makeArticle(
        id: '3',
        category: 'tech',
        publishedAt: now,
      ),
    ];

    await cacheService.insertArticles(articles);
    final result = await cacheService.getArticlesByCategory('tech');

    expect(result[0].id, '3');
    expect(result[1].id, '2');
    expect(result[2].id, '1');
  });
}
