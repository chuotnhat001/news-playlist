import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/providers/content_provider.dart';
import 'package:news_playlist/services/audio_player_service.dart';
import 'package:news_playlist/services/cache_service.dart';

class AudioPlayerState {
  final List<Article> playlist;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isLoading;
  final String? error;
  final String? category;
  final String? categoryUrl;

  const AudioPlayerState({
    this.playlist = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isLoading = false,
    this.error,
    this.category,
    this.categoryUrl,
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
    String? category,
    String? categoryUrl,
  }) {
    return AudioPlayerState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      category: category ?? this.category,
      categoryUrl: categoryUrl ?? this.categoryUrl,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final NewsAudioService _audioService;
  final NewsAudioHandler? _audioHandler;
  final CacheService? _cacheService;
  StreamSubscription<PlaybackState>? _playbackSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<dynamic>? _customEventSub;
  Timer? _saveTimer;
  Completer<void>? _readyCompleter;
  int _retryCount = 0;
  static const _maxRetries = 1;

  AudioPlayerNotifier(this._audioService, [this._audioHandler, this._cacheService])
      : super(const AudioPlayerState()) {
    _playbackSub = _audioService.playbackStateStream.listen(_onPlaybackState);
    _positionSub = _audioService.positionStream.listen(_onPosition);
    _durationSub = _audioService.durationStream.listen(_onDuration);
    _customEventSub = _audioHandler?.customEvent.listen(_onCustomEvent);
  }

  void _onPlaybackState(PlaybackState playbackState) {
    switch (playbackState) {
      case PlaybackState.playing:
        _retryCount = 0;
        state = state.copyWith(isPlaying: true, isLoading: false);
        break;
      case PlaybackState.paused:
        state = state.copyWith(isPlaying: false, isLoading: false);
        _savePlaybackState();
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
    if (_cacheService != null && _cacheService.isReady && state.category != null && state.playlist.isNotEmpty) {
      _scheduleSave();
    }
  }

  void _onDuration(Duration? duration) {
    if (duration != null) {
      state = state.copyWith(duration: duration);
      _readyCompleter?.complete();
      _readyCompleter = null;
    }
  }

  void _onCustomEvent(dynamic event) {
    if (event == 'skipNext') {
      skipNext();
    } else if (event == 'skipPrevious') {
      skipPrevious();
    }
  }

  Future<void> setPlaylist(List<Article> articles, {String? category, String? categoryUrl}) async {
    if (articles.isEmpty) {
      state = const AudioPlayerState();
      return;
    }
    state = state.copyWith(
      playlist: articles,
      currentIndex: 0,
      position: Duration.zero,
      duration: Duration.zero,
      category: category ?? articles.first.category,
      categoryUrl: categoryUrl,
    );
    await _playCurrentTrack();
  }

  Future<void> playFromIndex(List<Article> articles, int index, {String? category, String? categoryUrl}) async {
    if (articles.isEmpty || index < 0 || index >= articles.length) return;
    state = state.copyWith(
      playlist: articles,
      currentIndex: index,
      position: Duration.zero,
      duration: Duration.zero,
      category: category ?? articles.first.category,
      categoryUrl: categoryUrl,
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

  /// Waits for audio source to be ready (duration emitted), then seeks.
  Future<void> seekWhenReady(Duration position) async {
    if (state.duration > Duration.zero) {
      await _audioService.seek(position);
      return;
    }
    _readyCompleter = Completer<void>();
    await _readyCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
    await _audioService.seek(position);
  }

  void saveState() {
    _saveTimer?.cancel();
    _savePlaybackState();
  }

  void _onTrackComplete() {
    _retryCount = 0;
    skipNext();
  }

  void _onPlaybackError() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      _playCurrentTrack();
    } else {
      _retryCount = 0;
      state = state.copyWith(error: 'Playback error on current track');
      skipNext();
    }
  }

  Future<void> _playCurrentTrack() async {
    final article = state.currentArticle;
    if (article == null) return;
    _audioHandler?.setCurrentMediaItem(
      title: article.title,
      artist: article.source,
    );
    try {
      await _audioService.playUrl(
        article.audioUrl,
        title: article.title,
        artist: article.source,
      );
    } catch (_) {
      _onPlaybackError();
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _savePlaybackState();
    _playbackSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _customEventSub?.cancel();
    _audioService.dispose();
    _audioHandler?.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    if (_saveTimer?.isActive ?? false) return;
    _saveTimer = Timer(const Duration(seconds: 5), _savePlaybackState);
  }

  void _savePlaybackState() {
    if (_cacheService == null || !_cacheService.isReady) return;
    final s = state;
    if (s.playlist.isEmpty || s.category == null) return;
    _cacheService.savePlaybackState(
      category: s.category!,
      categoryUrl: s.categoryUrl,
      articleIndex: s.currentIndex,
      positionMs: s.position.inMilliseconds,
    );
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
    ref.read(cacheServiceProvider),
  );
});
