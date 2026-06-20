import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/services/audio_player_service.dart';

class AudioPlayerState {
  final List<Article> playlist;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isLoading;
  final String? error;

  const AudioPlayerState({
    this.playlist = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isLoading = false,
    this.error,
  });

  Article? get currentArticle =>
      playlist.isEmpty ? null : playlist[currentIndex];

  AudioPlayerState copyWith({
    List<Article>? playlist,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isLoading,
    String? error,
  }) {
    return AudioPlayerState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final NewsAudioService _audioService;
  final NewsAudioHandler? _audioHandler;
  StreamSubscription<PlaybackState>? _playbackSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<dynamic>? _customEventSub;

  AudioPlayerNotifier(this._audioService, [this._audioHandler])
      : super(const AudioPlayerState()) {
    _playbackSub = _audioService.playbackStateStream.listen(_onPlaybackState);
    _positionSub = _audioService.positionStream.listen(_onPosition);
    _durationSub = _audioService.durationStream.listen(_onDuration);
    _customEventSub = _audioHandler?.customEvent.listen(_onCustomEvent);
  }

  void _onPlaybackState(PlaybackState playbackState) {
    switch (playbackState) {
      case PlaybackState.playing:
        state = state.copyWith(isPlaying: true, isLoading: false);
        break;
      case PlaybackState.paused:
        state = state.copyWith(isPlaying: false, isLoading: false);
        break;
      case PlaybackState.loading:
        state = state.copyWith(isLoading: true);
        break;
      case PlaybackState.completed:
        _onTrackComplete();
        break;
      case PlaybackState.error:
        _onPlaybackError();
        break;
      case PlaybackState.idle:
        state = state.copyWith(isPlaying: false, isLoading: false);
        break;
    }
  }

  void _onPosition(Duration position) {
    state = state.copyWith(position: position);
  }

  void _onDuration(Duration? duration) {
    if (duration != null) {
      state = state.copyWith(duration: duration);
    }
  }

  void _onCustomEvent(dynamic event) {
    if (event == 'skipNext') {
      skipNext();
    } else if (event == 'skipPrevious') {
      skipPrevious();
    }
  }

  Future<void> setPlaylist(List<Article> articles) async {
    if (articles.isEmpty) {
      state = const AudioPlayerState();
      return;
    }
    state = state.copyWith(
      playlist: articles,
      currentIndex: 0,
      position: Duration.zero,
      duration: Duration.zero,
    );
    await _playCurrentTrack();
  }

  Future<void> play() async {
    await _playCurrentTrack();
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> resume() async {
    await _audioService.resume();
  }

  Future<void> skipNext() async {
    if (state.playlist.isEmpty) return;
    if (state.currentIndex < state.playlist.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        position: Duration.zero,
        duration: Duration.zero,
      );
      await _playCurrentTrack();
    } else {
      await _audioService.stop();
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> skipPrevious() async {
    if (state.playlist.isEmpty) return;
    if (state.currentIndex > 0) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        position: Duration.zero,
        duration: Duration.zero,
      );
      await _playCurrentTrack();
    } else {
      await seekTo(Duration.zero);
    }
  }

  Future<void> seekTo(Duration position) async {
    await _audioService.seek(position);
  }

  void _onTrackComplete() {
    skipNext();
  }

  void _onPlaybackError() {
    state = state.copyWith(error: 'Playback error on current track');
    skipNext();
  }

  Future<void> _playCurrentTrack() async {
    final article = state.currentArticle;
    if (article == null) return;
    _audioHandler?.setCurrentMediaItem(
      title: article.title,
      artist: article.source,
    );
    await _audioService.playUrl(
      article.audioUrl,
      title: article.title,
      artist: article.source,
    );
  }

  @override
  void dispose() {
    _playbackSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _customEventSub?.cancel();
    _audioService.dispose();
    _audioHandler?.dispose();
    super.dispose();
  }
}

final newsAudioServiceProvider = Provider<NewsAudioService>((ref) {
  final service = JustAudioNewsService();
  ref.onDispose(() => service.dispose());
  return service;
});

final audioHandlerProvider = Provider<NewsAudioHandler?>((ref) {
  return null;
});

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier(
    ref.read(newsAudioServiceProvider),
    ref.read(audioHandlerProvider),
  );
});
