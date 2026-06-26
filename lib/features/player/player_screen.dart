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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D0D2B),
                Color(0xFF1A1A4E),
                Color(0xFF0A2647),
                Color(0xFF144272),
              ],
              stops: [0.0, 0.35, 0.65, 1.0],
            ),
          ),
          child: const Center(
            child: Text(
              'Chưa chọn bài nghe',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Đang phát',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D2B),
              Color(0xFF1A1A4E),
              Color(0xFF0A2647),
              Color(0xFF144272),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
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
                'Bài ${state.currentIndex + 1} / ${state.playlist.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
