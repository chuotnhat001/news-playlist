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
          icon: const Icon(Icons.skip_previous),
          iconSize: 36,
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
          icon: Icon(
            state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          ),
          iconSize: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: isLast ? null : () => notifier.skipNext(),
          icon: const Icon(Icons.skip_next),
          iconSize: 36,
        ),
      ],
    );
  }
}
