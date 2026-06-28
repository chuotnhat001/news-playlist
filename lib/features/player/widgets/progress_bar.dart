import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/providers/audio_player_provider.dart';

class ProgressBar extends ConsumerWidget {
  const ProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(
      audioPlayerProvider.select((s) => s.position),
    );
    final duration = ref.watch(
      audioPlayerProvider.select((s) => s.duration),
    );
    final isLoading = ref.watch(
      audioPlayerProvider.select((s) => s.isLoading),
    );
    final maxMillis = duration.inMilliseconds.toDouble();

    return Column(
      children: [
        if (isLoading)
          const LinearProgressIndicator(minHeight: 4)
        else
          Slider(
            value: maxMillis > 0
                ? position.inMilliseconds.toDouble().clamp(0, maxMillis)
                : 0,
            max: maxMillis > 0 ? maxMillis : 1,
            onChanged: maxMillis > 0
                ? (value) {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .seekTo(Duration(milliseconds: value.toInt()));
                  }
                : null,
            semanticFormatterCallback: (value) {
              final pos = Duration(milliseconds: value.toInt());
              return '${_formatDuration(pos)} / ${_formatDuration(duration)}';
            },
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              Text(
                _formatDuration(duration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
