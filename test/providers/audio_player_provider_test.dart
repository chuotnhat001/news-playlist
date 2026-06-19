import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/audio_player_service.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';

class MockNewsAudioService implements NewsAudioService {
  final StreamController<PlaybackState> playbackStateController =
      StreamController<PlaybackState>.broadcast();
  final StreamController<Duration> positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> durationController =
      StreamController<Duration?>.broadcast();

  String? lastPlayedUrl;
  bool pauseCalled = false;
  bool resumeCalled = false;
  bool stopCalled = false;
  Duration? lastSeekPosition;

  @override
  Stream<PlaybackState> get playbackStateStream =>
      playbackStateController.stream;

  @override
  Stream<Duration> get positionStream => positionController.stream;

  @override
  Stream<Duration?> get durationStream => durationController.stream;

  @override
  Future<void> playUrl(String url) async {
    lastPlayedUrl = url;
    playbackStateController.add(PlaybackState.playing);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    playbackStateController.add(PlaybackState.paused);
  }

  @override
  Future<void> resume() async {
    resumeCalled = true;
    playbackStateController.add(PlaybackState.playing);
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    playbackStateController.add(PlaybackState.paused);
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
  }

  @override
  Future<void> dispose() async {
    await playbackStateController.close();
    await positionController.close();
    await durationController.close();
  }
}

Article _createArticle(String id) {
  return Article(
    id: id,
    title: 'Article $id',
    source: 'Test Source',
    audioUrl: 'https://example.com/audio/$id.mp3',
    articleUrl: 'https://example.com/article/$id',
    category: 'test',
    publishedAt: DateTime(2024, 1, 1),
    cachedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late MockNewsAudioService mockService;
  late AudioPlayerNotifier notifier;

  setUp(() {
    mockService = MockNewsAudioService();
    notifier = AudioPlayerNotifier(mockService);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('AudioPlayerNotifier', () {
    test('setPlaylist sets currentArticle to first item and plays', () async {
      final articles = [_createArticle('1'), _createArticle('2')];

      await notifier.setPlaylist(articles);

      expect(notifier.state.playlist, articles);
      expect(notifier.state.currentIndex, 0);
      expect(notifier.state.currentArticle, articles[0]);
      expect(mockService.lastPlayedUrl, 'https://example.com/audio/1.mp3');
    });

    test('skipNext advances to next track', () async {
      final articles = [
        _createArticle('1'),
        _createArticle('2'),
        _createArticle('3'),
      ];
      await notifier.setPlaylist(articles);

      await notifier.skipNext();

      expect(notifier.state.currentIndex, 1);
      expect(notifier.state.currentArticle, articles[1]);
      expect(mockService.lastPlayedUrl, 'https://example.com/audio/2.mp3');
    });

    test('skipNext at end stops playback', () async {
      final articles = [_createArticle('1'), _createArticle('2')];
      await notifier.setPlaylist(articles);

      // Move to last track
      await notifier.skipNext();
      // Try to skip past end
      await notifier.skipNext();

      expect(notifier.state.currentIndex, 1); // stays at last
      expect(mockService.stopCalled, true);
    });

    test('skipPrevious at index 0 seeks to start', () async {
      final articles = [_createArticle('1'), _createArticle('2')];
      await notifier.setPlaylist(articles);

      await notifier.skipPrevious();

      expect(notifier.state.currentIndex, 0);
      expect(mockService.lastSeekPosition, Duration.zero);
    });

    test('skipPrevious decrements index and plays', () async {
      final articles = [_createArticle('1'), _createArticle('2')];
      await notifier.setPlaylist(articles);
      await notifier.skipNext(); // move to index 1

      await notifier.skipPrevious();

      expect(notifier.state.currentIndex, 0);
      expect(mockService.lastPlayedUrl, 'https://example.com/audio/1.mp3');
    });

    test('auto-next on track completion', () async {
      final articles = [_createArticle('1'), _createArticle('2')];
      await notifier.setPlaylist(articles);

      // Simulate track completion
      mockService.playbackStateController.add(PlaybackState.completed);
      // Allow stream event to propagate
      await Future.delayed(Duration.zero);

      expect(notifier.state.currentIndex, 1);
      expect(mockService.lastPlayedUrl, 'https://example.com/audio/2.mp3');
    });

    test('skip-on-error advances to next track', () async {
      final articles = [_createArticle('1'), _createArticle('2')];
      await notifier.setPlaylist(articles);

      // Simulate playback error
      mockService.playbackStateController.add(PlaybackState.error);
      // Allow stream event to propagate
      await Future.delayed(Duration.zero);

      // Error handler triggers skipNext, advancing to the next track
      expect(notifier.state.currentIndex, 1);
      expect(mockService.lastPlayedUrl, 'https://example.com/audio/2.mp3');
    });

    test('empty playlist is safe', () async {
      await notifier.setPlaylist([]);

      expect(notifier.state.playlist, isEmpty);
      expect(notifier.state.currentArticle, isNull);

      // Operations on empty playlist should not throw
      await notifier.skipNext();
      await notifier.skipPrevious();
      await notifier.play();

      expect(notifier.state.currentIndex, 0);
    });

    test('pause delegates to audio service', () async {
      final articles = [_createArticle('1')];
      await notifier.setPlaylist(articles);

      await notifier.pause();

      expect(mockService.pauseCalled, true);
    });

    test('resume delegates to audio service', () async {
      final articles = [_createArticle('1')];
      await notifier.setPlaylist(articles);
      await notifier.pause();

      await notifier.resume();

      expect(mockService.resumeCalled, true);
    });

    test('seekTo delegates to audio service', () async {
      final articles = [_createArticle('1')];
      await notifier.setPlaylist(articles);

      await notifier.seekTo(const Duration(seconds: 30));

      expect(mockService.lastSeekPosition, const Duration(seconds: 30));
    });

    test('position stream updates state', () async {
      final articles = [_createArticle('1')];
      await notifier.setPlaylist(articles);

      mockService.positionController.add(const Duration(seconds: 15));
      await Future.delayed(Duration.zero);

      expect(notifier.state.position, const Duration(seconds: 15));
    });

    test('duration stream updates state', () async {
      final articles = [_createArticle('1')];
      await notifier.setPlaylist(articles);

      mockService.durationController.add(const Duration(minutes: 3));
      await Future.delayed(Duration.zero);

      expect(notifier.state.duration, const Duration(minutes: 3));
    });
  });
}
