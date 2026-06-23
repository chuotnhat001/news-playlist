import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';
import 'package:news_playlist/services/audio_player_service.dart';

class MockAudioService implements NewsAudioService {
  final _playbackController = StreamController<PlaybackState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  Duration? lastSeekPosition;
  bool pauseCalled = false;
  bool resumeCalled = false;
  String? lastPlayedUrl;

  @override
  Stream<PlaybackState> get playbackStateStream => _playbackController.stream;
  @override
  Stream<Duration> get positionStream => _positionController.stream;
  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Future<void> playUrl(String url, {String? title, String? artist}) async {
    lastPlayedUrl = url;
    _playbackController.add(PlaybackState.playing);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    _playbackController.add(PlaybackState.paused);
  }

  @override
  Future<void> resume() async {
    resumeCalled = true;
    _playbackController.add(PlaybackState.playing);
  }

  @override
  Future<void> stop() async {
    _playbackController.add(PlaybackState.idle);
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
  }

  @override
  Future<void> dispose() async {
    await _playbackController.close();
    await _positionController.close();
    await _durationController.close();
  }

  void emitPosition(Duration d) => _positionController.add(d);
  void emitDuration(Duration? d) => _durationController.add(d);
  void emitState(PlaybackState s) => _playbackController.add(s);
}

final _mockArticles = [
  Article(
    id: 'a1',
    title: 'Article 1',
    source: 'soha',
    audioUrl: 'https://example.com/1.mp3',
    articleUrl: 'https://example.com/1',
    category: 'cong-nghe',
    publishedAt: DateTime(2026, 6, 20),
    cachedAt: DateTime(2026, 6, 20),
  ),
  Article(
    id: 'a2',
    title: 'Article 2',
    source: 'soha',
    audioUrl: 'https://example.com/2.mp3',
    articleUrl: 'https://example.com/2',
    category: 'cong-nghe',
    publishedAt: DateTime(2026, 6, 19),
    cachedAt: DateTime(2026, 6, 20),
  ),
  Article(
    id: 'a3',
    title: 'Article 3',
    source: 'soha',
    audioUrl: 'https://example.com/3.mp3',
    articleUrl: 'https://example.com/3',
    category: 'cong-nghe',
    publishedAt: DateTime(2026, 6, 18),
    cachedAt: DateTime(2026, 6, 20),
  ),
];

void main() {
  late MockAudioService mockService;
  late AudioPlayerNotifier notifier;

  setUp(() {
    mockService = MockAudioService();
    notifier = AudioPlayerNotifier(mockService);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('AudioPlayerNotifier lifecycle', () {
    test('seekTo calls service.seek with correct position', () async {
      await notifier.seekTo(const Duration(seconds: 30));
      expect(mockService.lastSeekPosition, const Duration(seconds: 30));
    });

    test('pause calls service.pause and updates state', () async {
      await notifier.setPlaylist(_mockArticles);
      await notifier.pause();

      expect(mockService.pauseCalled, isTrue);
      // Wait for stream to propagate
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.isPlaying, isFalse);
    });

    test('resume calls service.resume and updates state', () async {
      await notifier.setPlaylist(_mockArticles);
      await notifier.pause();
      await notifier.resume();

      expect(mockService.resumeCalled, isTrue);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.isPlaying, isTrue);
    });

    test('setPlaylist starts playing first track', () async {
      await notifier.setPlaylist(_mockArticles);

      expect(mockService.lastPlayedUrl, 'https://example.com/1.mp3');
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.playlist.length, 3);
    });

    test('skipNext advances to next track', () async {
      await notifier.setPlaylist(_mockArticles);
      await notifier.skipNext();

      expect(notifier.state.currentIndex, 1);
      expect(mockService.lastPlayedUrl, 'https://example.com/2.mp3');
    });

    test('skipNext at last track stops playback', () async {
      await notifier.playFromIndex(_mockArticles, 2);
      await notifier.skipNext();

      await Future.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.isPlaying, isFalse);
    });

    test('skipPrevious goes to previous track', () async {
      await notifier.playFromIndex(_mockArticles, 2);
      await notifier.skipPrevious();

      expect(notifier.state.currentIndex, 1);
      expect(mockService.lastPlayedUrl, 'https://example.com/2.mp3');
    });

    test('skipPrevious at first track seeks to beginning', () async {
      await notifier.setPlaylist(_mockArticles);
      await notifier.skipPrevious();

      expect(notifier.state.currentIndex, 0);
      expect(mockService.lastSeekPosition, Duration.zero);
    });

    test('position stream updates state', () async {
      mockService.emitPosition(const Duration(seconds: 45));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.position, const Duration(seconds: 45));
    });

    test('duration stream updates state', () async {
      mockService.emitDuration(const Duration(minutes: 3));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.duration, const Duration(minutes: 3));
    });

    test('loading state is set correctly', () async {
      mockService.emitState(PlaybackState.loading);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.isLoading, isTrue);
    });

    test('track completion auto-advances', () async {
      await notifier.setPlaylist(_mockArticles);
      mockService.emitState(PlaybackState.completed);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.currentIndex, 1);
    });

    test('playFromIndex with category sets category in state', () async {
      await notifier.playFromIndex(_mockArticles, 1, category: 'kinh-doanh');

      expect(notifier.state.category, 'kinh-doanh');
      expect(notifier.state.currentIndex, 1);
    });

    test('setPlaylist with empty list resets state', () async {
      await notifier.setPlaylist(_mockArticles);
      await notifier.setPlaylist([]);

      expect(notifier.state.playlist, isEmpty);
      expect(notifier.state.currentIndex, 0);
    });
  });
}
