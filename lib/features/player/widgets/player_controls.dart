import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/providers/audio_player_provider.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(audioPlayerProvider.select((s) => s.isLoading));
    final currentIndex = ref.watch(audioPlayerProvider.select((s) => s.currentIndex));
    final playlistLength = ref.watch(audioPlayerProvider.select((s) => s.playlist.length));
    final notifier = ref.read(audioPlayerProvider.notifier);
    final isFirst = currentIndex == 0;
    final isLast = currentIndex >= playlistLength - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: isFirst ? null : () => notifier.skipPrevious(),
          tooltip: 'Bài trước',
          icon: const Icon(Icons.skip_previous),
          iconSize: 36,
          color: Colors.white,
          disabledColor: Colors.white38,
          style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {
            if (isPlaying) {
              notifier.pause();
            } else {
              notifier.resume();
            }
          },
          tooltip: isPlaying ? 'Tạm dừng' : 'Phát',
          icon: isLoading
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF00DCFF),
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                ),
          iconSize: 64,
          color: const Color(0xFF00DCFF),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: isLast ? null : () => notifier.skipNext(),
          tooltip: 'Bài tiếp',
          icon: const Icon(Icons.skip_next),
          iconSize: 36,
          color: Colors.white,
          disabledColor: Colors.white38,
          style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
        ),
      ],
    );
  }
}
