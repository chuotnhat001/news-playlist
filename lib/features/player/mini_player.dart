import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/player/player_screen.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(
      audioPlayerProvider.select((s) => s.currentArticle),
    );

    if (article == null) {
      return const SizedBox.shrink();
    }

    final duration = ref.watch(
      audioPlayerProvider.select((s) => s.duration),
    );
    final position = ref.watch(
      audioPlayerProvider.select((s) => s.position),
    );
    final isLoading = ref.watch(
      audioPlayerProvider.select((s) => s.isLoading),
    );
    final isPlaying = ref.watch(
      audioPlayerProvider.select((s) => s.isPlaying),
    );
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Semantics(
      label: 'Đang phát: ${article.title}, ${article.source}',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D2B),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: isLoading ? null : progress.clamp(0.0, 1.0),
                minHeight: 2,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, size: 24, color: Color(0xFF00DCFF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            article.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          Text(
                            article.source,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: isPlaying ? 'Tạm dừng' : 'Phát',
                      button: true,
                      child: IconButton(
                        onPressed: () {
                          final notifier =
                              ref.read(audioPlayerProvider.notifier);
                          if (isPlaying) {
                            notifier.pause();
                          } else {
                            notifier.resume();
                          }
                        },
                        tooltip: '',
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
