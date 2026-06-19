import 'package:just_audio/just_audio.dart';

enum PlaybackState { idle, loading, playing, paused, completed, error }

abstract class NewsAudioService {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<PlaybackState> get playbackStateStream;

  Future<void> playUrl(String url);
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
  Future<void> playUrl(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      // Error state will be emitted through playerStateStream
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
