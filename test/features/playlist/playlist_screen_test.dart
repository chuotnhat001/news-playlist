import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/playlist/playlist_screen.dart';
import 'package:news_playlist/providers/content_provider.dart';
import 'package:news_playlist/models/article.dart';

final _mockArticles = [
  Article(
    id: 'mock-1',
    title: 'Mock Article One',
    source: 'soha',
    audioUrl: 'https://example.com/audio1.mp3',
    articleUrl: 'https://example.com/article1',
    category: 'cong-nghe',
    publishedAt: DateTime(2026, 6, 20),
    cachedAt: DateTime(2026, 6, 20),
  ),
  Article(
    id: 'mock-2',
    title: 'Mock Article Two',
    source: 'soha',
    audioUrl: 'https://example.com/audio2.mp3',
    articleUrl: 'https://example.com/article2',
    category: 'cong-nghe',
    publishedAt: DateTime(2026, 6, 19),
    cachedAt: DateTime(2026, 6, 20),
  ),
];

void main() {
  group('PlaylistScreen', () {
    testWidgets('shows articles when loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            articlesProvider('cong-nghe').overrideWith(
              (ref) async => _mockArticles,
            ),
          ],
          child: const MaterialApp(
            home: PlaylistScreen(category: 'cong-nghe'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mock Article One'), findsOneWidget);
      expect(find.text('Mock Article Two'), findsOneWidget);
      expect(find.text('Phát tất cả'), findsOneWidget);
    });

    testWidgets('shows empty state when no articles', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            articlesProvider('cong-nghe').overrideWith(
              (ref) async => <Article>[],
            ),
          ],
          child: const MaterialApp(
            home: PlaylistScreen(category: 'cong-nghe'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy bài viết'), findsOneWidget);
      expect(find.text('Kéo xuống để tải lại'), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            articlesProvider('cong-nghe').overrideWith(
              (ref) async => throw Exception('Network error'),
            ),
          ],
          child: const MaterialApp(
            home: PlaylistScreen(category: 'cong-nghe'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Không tải được bài viết'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
