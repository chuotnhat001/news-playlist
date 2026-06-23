import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

enum PlaybackState { idle, loading, playing, paused, completed, error }

abstract class NewsAudioService {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<PlaybackState> get playbackStateStream;

  Future<void> playUrl(String url, {String? title, String? artist});
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

class JustAudioNewsService implements NewsAudioService {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<PlaybackState> get playbackStateStream =>
      _player.playerStateStream.map((state) {
        if (state.processingState == ProcessingState.completed) {
          return PlaybackState.completed;
        }
        if (state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering) {
          return PlaybackState.loading;
        }
        if (state.playing) return PlaybackState.playing;
        return PlaybackState.paused;
      });

  @override
  Future<void> playUrl(String url, {String? title, String? artist}) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      // Emit error through playerStateStream indirectly — just_audio handles this
      // via ProcessingState, but setUrl failures throw before the stream updates.
      // Re-throw so callers can handle.
      rethrow;
    }
  }

  @override
  Future<void> pause() async => await _player.pause();

  @override
  Future<void> resume() async => await _player.play();

  @override
  Future<void> stop() async => await _player.stop();

  @override
  Future<void> seek(Duration position) async => await _player.seek(position);

  @override
  Future<void> dispose() async => await _player.dispose();
}

class NewsAudioHandler extends BaseAudioHandler with SeekHandler {
  final NewsAudioService _service;
  StreamSubscription<PlaybackState>? _playbackSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  NewsAudioHandler(this._service) {
    _playbackSub = _service.playbackStateStream.listen(_onPlaybackState);
    _positionSub = _service.positionStream.listen(_onPosition);
    _durationSub = _service.durationStream.listen(_onDuration);
  }

  void _onPlaybackState(PlaybackState state) {
    final playing = state == PlaybackState.playing;
    final processingState = switch (state) {
      PlaybackState.idle => AudioProcessingState.idle,
      PlaybackState.loading => AudioProcessingState.loading,
      PlaybackState.playing => AudioProcessingState.ready,
      PlaybackState.paused => AudioProcessingState.ready,
      PlaybackState.completed => AudioProcessingState.completed,
      PlaybackState.error => AudioProcessingState.error,
    };

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      playing: playing,
      processingState: processingState,
    ));
  }

  void _onPosition(Duration position) {
    playbackState.add(playbackState.value.copyWith(
      updatePosition: position,
    ));
  }

  void _onDuration(Duration? duration) {
    mediaItem.add(mediaItem.value?.copyWith(duration: duration));
  }

  void setCurrentMediaItem({required String title, required String artist}) {
    mediaItem.add(MediaItem(
      id: title,
      title: title,
      artist: artist,
    ));
  }

  @override
  Future<void> play() async => await _service.resume();

  @override
  Future<void> pause() async => await _service.pause();

  @override
  Future<void> stop() async {
    await _service.stop();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async => await _service.seek(position);

  @override
  Future<void> skipToNext() async {
    // Handled by AudioPlayerNotifier
    customEvent.add('skipNext');
  }

  @override
  Future<void> skipToPrevious() async {
    // Handled by AudioPlayerNotifier
    customEvent.add('skipPrevious');
  }

  Future<void> dispose() async {
    await _playbackSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
  }
}

Future<NewsAudioHandler> initAudioHandler(NewsAudioService service) async {
  return await AudioService.init(
    builder: () => NewsAudioHandler(service),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.newsplaylist.audio',
      androidNotificationChannelName: 'News Playlist',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}
