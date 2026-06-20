import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/playlist/widgets/article_tile.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';
import 'package:news_playlist/providers/content_provider.dart';
import 'package:news_playlist/services/analytics_service.dart';
import 'package:news_playlist/shared/widgets/empty_state.dart';
import 'package:news_playlist/shared/widgets/error_toast.dart';

class PlaylistScreen extends ConsumerWidget {
  final String category;

  const PlaylistScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatCategory(category)),
      ),
      body: articlesAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load articles',
          subtitle: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(articlesProvider(category)),
        ),
        data: (articles) {
          if (articles.isEmpty) {
            return EmptyState(
              icon: Icons.article_outlined,
              title: 'No articles found',
              subtitle: 'Pull down to refresh',
              actionLabel: 'Refresh',
              onAction: () => ref.invalidate(articlesProvider(category)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final contentService = ref.read(contentServiceProvider);
              try {
                await contentService.refreshCategory(category);
                ref.invalidate(articlesProvider(category));
              } catch (e) {
                if (context.mounted) {
                  showErrorToast(context, 'Refresh failed: $e');
                }
              }
            },
            child: ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return ArticleTile(article: articles[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: articlesAsync.whenOrNull(
        data: (articles) => articles.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  AnalyticsService().logPlayAll(category, articles.length);
                  ref
                      .read(audioPlayerProvider.notifier)
                      .setPlaylist(articles);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play All'),
              )
            : null,
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCategory(String category) {
    return category.split('-').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
