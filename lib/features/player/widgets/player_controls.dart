import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/providers/audio_player_provider.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    final isFirst = state.currentIndex == 0;
    final isLast = state.currentIndex >= state.playlist.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: isFirst ? null : () => notifier.skipPrevious(),
          tooltip: '',
          icon: const Icon(Icons.skip_previous),
          iconSize: 36,
          color: Colors.white,
          disabledColor: Colors.white38,
          style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {
            if (state.isPlaying) {
              notifier.pause();
            } else {
              notifier.resume();
            }
          },
          tooltip: '',
          icon: state.isLoading
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF00DCFF),
                  ),
                )
              : Icon(
                  state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                ),
          iconSize: 64,
          color: const Color(0xFF00DCFF),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: isLast ? null : () => notifier.skipNext(),
          tooltip: '',
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
