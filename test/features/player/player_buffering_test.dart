import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/player/widgets/player_controls.dart';
import 'package:news_playlist/features/player/widgets/progress_bar.dart';
import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';
import 'package:news_playlist/services/audio_player_service.dart';

class FakeAudioService implements NewsAudioService {
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<PlaybackState> get playbackStateStream => const Stream.empty();
  @override
  Future<void> playUrl(String url, {String? title, String? artist}) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> dispose() async {}
}

final _mockArticles = [
  Article(
    id: 'mock-1',
    title: 'Mock Article',
    source: 'soha',
    audioUrl: 'https://example.com/audio1.mp3',
    articleUrl: 'https://example.com/article1',
    category: 'cong-nghe',
    publishedAt: DateTime(2026, 6, 20),
    cachedAt: DateTime(2026, 6, 20),
  ),
];

void main() {
  group('PlayerControls buffering state', () {
    testWidgets('shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            newsAudioServiceProvider.overrideWithValue(FakeAudioService()),
            audioPlayerProvider.overrideWith((ref) {
              final notifier = AudioPlayerNotifier(FakeAudioService());
              notifier.state = AudioPlayerState(
                playlist: _mockArticles,
                currentIndex: 0,
                isLoading: true,
                isPlaying: false,
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: PlayerControls())),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_filled), findsNothing);
    });

    testWidgets('shows play icon when not loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            newsAudioServiceProvider.overrideWithValue(FakeAudioService()),
            audioPlayerProvider.overrideWith((ref) {
              final notifier = AudioPlayerNotifier(FakeAudioService());
              notifier.state = AudioPlayerState(
                playlist: _mockArticles,
                currentIndex: 0,
                isLoading: false,
                isPlaying: false,
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: PlayerControls())),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });
  });

  group('ProgressBar buffering state', () {
    testWidgets('shows indeterminate LinearProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            newsAudioServiceProvider.overrideWithValue(FakeAudioService()),
            audioPlayerProvider.overrideWith((ref) {
              final notifier = AudioPlayerNotifier(FakeAudioService());
              notifier.state = const AudioPlayerState(
                isLoading: true,
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: ProgressBar())),
        ),
      );

      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('shows Slider when not loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            newsAudioServiceProvider.overrideWithValue(FakeAudioService()),
            audioPlayerProvider.overrideWith((ref) {
              final notifier = AudioPlayerNotifier(FakeAudioService());
              notifier.state = const AudioPlayerState(
                isLoading: false,
                duration: Duration(seconds: 120),
                position: Duration(seconds: 30),
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: ProgressBar())),
        ),
      );

      await tester.pump();

      expect(find.byType(Slider), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
