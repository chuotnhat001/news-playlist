import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/settings/settings_screen.dart';
import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/models/category_config.dart';
import 'package:news_playlist/services/cache_service.dart';
import 'package:news_playlist/services/content_service.dart';
import 'package:news_playlist/services/crawler_service.dart';
import 'package:news_playlist/providers/content_provider.dart';

class FakeCacheService extends CacheService {
  List<CategoryConfig> categories = [];

  @override
  bool get isReady => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> clearExpired() async {}

  @override
  Future<List<CategoryConfig>> getCategories() async => categories;

  @override
  Future<void> insertCategory(CategoryConfig category) async {
    categories.add(category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<int> getArticleCount(String categoryId) async => 0;

  @override
  Future<bool> isStale(String category) async => false;

  @override
  Future<List<Article>> getArticlesByCategory(String category) async => [];
}

void main() {
  late FakeCacheService fakeCacheService;
  late ContentService contentService;

  setUp(() {
    fakeCacheService = FakeCacheService();
    contentService = ContentService(
      cacheService: fakeCacheService,
      crawlerServices: <String, CrawlerService>{},
    );
  });

  group('SettingsScreen', () {
    testWidgets('renders form fields and add button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentServiceProvider.overrideWithValue(contentService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cấu hình danh mục'), findsOneWidget);
      expect(find.text('Tên danh mục'), findsOneWidget);
      expect(find.text('URL trang danh mục'), findsOneWidget);
      expect(find.text('Thêm danh mục'), findsOneWidget);
    });

    testWidgets('shows empty state when no categories', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentServiceProvider.overrideWithValue(contentService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Chưa có danh mục nào'), findsOneWidget);
    });

    testWidgets('shows existing categories', (tester) async {
      fakeCacheService.categories = [
        CategoryConfig(id: 'soha_quoc-te', name: 'Quốc tế', url: 'https://soha.vn/quoc-te.htm', source: 'soha'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentServiceProvider.overrideWithValue(contentService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quốc tế'), findsOneWidget);
      expect(find.byIcon(Icons.rss_feed), findsOneWidget);
    });

    testWidgets('does not add category with empty fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentServiceProvider.overrideWithValue(contentService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm danh mục'));
      await tester.pumpAndSettle();

      expect(fakeCacheService.categories, isEmpty);
    });

    testWidgets('does not add category with invalid URL', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentServiceProvider.overrideWithValue(contentService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Tên danh mục'), 'Test');
      await tester.enterText(find.widgetWithText(TextField, 'URL trang danh mục'), 'not-a-url');
      await tester.tap(find.text('Thêm danh mục'));
      await tester.pumpAndSettle();

      expect(fakeCacheService.categories, isEmpty);
    });

    testWidgets('adds category with valid input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentServiceProvider.overrideWithValue(contentService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Tên danh mục'), 'Quốc tế');
      await tester.enterText(find.widgetWithText(TextField, 'URL trang danh mục'), 'https://soha.vn/quoc-te.htm');
      await tester.tap(find.text('Thêm danh mục'));
      await tester.pumpAndSettle();

      expect(fakeCacheService.categories.length, 1);
      expect(fakeCacheService.categories.first.name, 'Quốc tế');
      expect(find.text('Quốc tế'), findsOneWidget);
    });

    testWidgets('delete button removes category', (tester) async {
      fakeCacheService.categories = [
        CategoryConfig(id: 'soha_test', name: 'Test Cat', url: 'https://soha.vn/test.htm', source: 'soha'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentServiceProvider.overrideWithValue(contentService),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Cat'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(fakeCacheService.categories, isEmpty);
    });
  });
}
