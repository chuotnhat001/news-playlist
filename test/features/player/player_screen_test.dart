import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/player/player_screen.dart';
import 'package:news_playlist/features/player/widgets/player_controls.dart';
import 'package:news_playlist/features/player/widgets/progress_bar.dart';
import 'package:news_playlist/features/player/widgets/track_info.dart';
import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';

void main() {
  final testArticles = [
    Article(
      id: 'test-1',
      title: 'First Article Title',
      source: 'soha',
      audioUrl: 'https://example.com/audio1.mp3',
      articleUrl: 'https://example.com/article1',
      category: 'cong-nghe',
      publishedAt: DateTime(2026, 6, 20),
      cachedAt: DateTime(2026, 6, 20),
    ),
    Article(
      id: 'test-2',
      title: 'Second Article Title',
      source: 'dantri',
      audioUrl: 'https://example.com/audio2.mp3',
      articleUrl: 'https://example.com/article2',
      category: 'cong-nghe',
      publishedAt: DateTime(2026, 6, 20),
      cachedAt: DateTime(2026, 6, 20),
    ),
  ];

  group('PlayerScreen', () {
    testWidgets('shows "No track selected" when no audio', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PlayerScreen()),
        ),
      );

      expect(find.text('Chưa chọn bài nghe'), findsOneWidget);
    });

    testWidgets('shows track info when playing', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(audioPlayerProvider.notifier).setPlaylist(testArticles);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PlayerScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Đang phát'), findsOneWidget);
      expect(find.text('First Article Title'), findsOneWidget);
      expect(find.text('soha'), findsOneWidget);
      expect(find.text('Bài 1 / 2'), findsOneWidget);
    });
  });

  group('PlayerControls', () {
    testWidgets('shows play/pause and skip buttons', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(audioPlayerProvider.notifier).setPlaylist(testArticles);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: PlayerControls())),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
      // Play or pause icon present
      expect(
        find.byWidgetPredicate((w) =>
            w is Icon &&
            (w.icon == Icons.play_circle_filled ||
                w.icon == Icons.pause_circle_filled)),
        findsOneWidget,
      );
    });

    testWidgets('previous disabled at first track', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(audioPlayerProvider.notifier).setPlaylist(testArticles);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: PlayerControls())),
        ),
      );
      await tester.pump();

      final prevButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.skip_previous),
      );
      expect(prevButton.onPressed, isNull);
    });
  });

  group('ProgressBar', () {
    testWidgets('shows slider and time labels', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: ProgressBar())),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('00:00'), findsNWidgets(2));
    });
  });

  group('TrackInfo', () {
    testWidgets('shows nothing when no track', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: TrackInfo())),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('shows article info when playing', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(audioPlayerProvider.notifier).setPlaylist(testArticles);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: TrackInfo())),
        ),
      );
      await tester.pump();

      expect(find.text('First Article Title'), findsOneWidget);
      expect(find.text('soha'), findsOneWidget);
      expect(find.byIcon(Icons.headphones), findsOneWidget);
    });
  });
}
