import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/player/widgets/player_controls.dart';
import 'package:news_playlist/features/player/widgets/progress_bar.dart';
import 'package:news_playlist/features/player/widgets/track_info.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerProvider);

    if (state.currentArticle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No track selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const TrackInfo(),
            const Spacer(),
            const ProgressBar(),
            const SizedBox(height: 16),
            const PlayerControls(),
            const SizedBox(height: 16),
            Text(
              'Track ${state.currentIndex + 1} of ${state.playlist.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
