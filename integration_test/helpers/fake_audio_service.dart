import 'dart:async';

import 'package:news_playlist/services/audio_player_service.dart';

class FakeNewsAudioService implements NewsAudioService {
  final _playbackController = StreamController<PlaybackState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  final List<String> playedUrls = [];
  int pauseCount = 0;
  int resumeCount = 0;
  Duration? lastSeekPosition;

  Duration fakeDuration = const Duration(minutes: 3);
  bool autoTransitionToPlaying = true;

  @override
  Stream<PlaybackState> get playbackStateStream => _playbackController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Future<void> playUrl(String url, {String? title, String? artist}) async {
    playedUrls.add(url);
    _playbackController.add(PlaybackState.loading);
    if (autoTransitionToPlaying) {
      await Future.delayed(const Duration(milliseconds: 50));
      _durationController.add(fakeDuration);
      _playbackController.add(PlaybackState.playing);
    }
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    _playbackController.add(PlaybackState.paused);
  }

  @override
  Future<void> resume() async {
    resumeCount++;
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
  Future<void> dispose() async {}

  void emitPosition(Duration pos) => _positionController.add(pos);
  void emitCompleted() => _playbackController.add(PlaybackState.completed);
  void emitPlaying() => _playbackController.add(PlaybackState.playing);
  void emitPaused() => _playbackController.add(PlaybackState.paused);
  void emitError() => _playbackController.add(PlaybackState.error);
}
