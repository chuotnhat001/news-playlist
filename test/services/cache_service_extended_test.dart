import 'package:flutter_test/flutter_test.dart';
import 'package:news_playlist/models/category_config.dart';
import 'package:news_playlist/services/cache_service_native.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late CacheServiceNative cacheService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    cacheService = CacheServiceNative();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await cacheService.initWithDatabase(db);
  });

  group('Init Guard', () {
    test('calling initWithDatabase twice does not throw', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      // Second call should be a no-op
      await cacheService.initWithDatabase(db);
      expect(cacheService.isReady, isTrue);
    });
  });

  group('Categories CRUD', () {
    final testCategory = CategoryConfig(
      id: 'soha_test-category',
      name: 'Test Category',
      url: 'https://soha.vn/test.htm',
      source: 'soha',
    );

    test('insertCategory and getCategories', () async {
      await cacheService.insertCategory(testCategory);
      final categories = await cacheService.getCategories();
      expect(categories.length, 1);
      expect(categories.first.id, testCategory.id);
      expect(categories.first.name, testCategory.name);
      expect(categories.first.url, testCategory.url);
      expect(categories.first.source, testCategory.source);
    });

    test('insertCategory replaces on conflict', () async {
      await cacheService.insertCategory(testCategory);
      final updated = CategoryConfig(
        id: testCategory.id,
        name: 'Updated Name',
        url: testCategory.url,
        source: testCategory.source,
      );
      await cacheService.insertCategory(updated);
      final categories = await cacheService.getCategories();
      expect(categories.length, 1);
      expect(categories.first.name, 'Updated Name');
    });

    test('deleteCategory removes category and its articles', () async {
      await cacheService.insertCategory(testCategory);
      await cacheService.deleteCategory(testCategory.id);
      final categories = await cacheService.getCategories();
      expect(categories, isEmpty);
    });

    test('getArticleCount returns 0 for empty category', () async {
      final count = await cacheService.getArticleCount('nonexistent');
      expect(count, 0);
    });
  });

  group('Playback State', () {
    test('savePlaybackState and getPlaybackState', () async {
      await cacheService.savePlaybackState(
        category: 'cong-nghe',
        categoryUrl: 'https://soha.vn/cong-nghe.htm',
        articleIndex: 3,
        positionMs: 45000,
      );
      final state = await cacheService.getPlaybackState();
      expect(state, isNotNull);
      expect(state!['category'], 'cong-nghe');
      expect(state['category_url'], 'https://soha.vn/cong-nghe.htm');
      expect(state['article_index'], 3);
      expect(state['position_ms'], 45000);
    });

    test('getPlaybackState returns null when empty', () async {
      final state = await cacheService.getPlaybackState();
      expect(state, isNull);
    });

    test('clearPlaybackState removes saved state', () async {
      await cacheService.savePlaybackState(
        category: 'cong-nghe',
        articleIndex: 1,
        positionMs: 1000,
      );
      await cacheService.clearPlaybackState();
      final state = await cacheService.getPlaybackState();
      expect(state, isNull);
    });

    test('savePlaybackState overwrites previous state', () async {
      await cacheService.savePlaybackState(
        category: 'cong-nghe',
        articleIndex: 1,
        positionMs: 1000,
      );
      await cacheService.savePlaybackState(
        category: 'kinh-doanh',
        articleIndex: 5,
        positionMs: 99000,
      );
      final state = await cacheService.getPlaybackState();
      expect(state!['category'], 'kinh-doanh');
      expect(state['article_index'], 5);
      expect(state['position_ms'], 99000);
    });
  });
}
