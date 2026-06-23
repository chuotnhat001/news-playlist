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
  final String? categoryUrl;

  const PlaylistScreen({super.key, required this.category, this.categoryUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = categoryUrl != null
        ? articlesFromUrlProvider((url: categoryUrl!, categoryId: category))
        : articlesProvider(category);
    final articlesAsync = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatCategory(category)),
      ),
      body: articlesAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Không tải được bài viết',
          subtitle: error.toString(),
          actionLabel: 'Thử lại',
          onAction: () => ref.invalidate(provider),
        ),
        data: (articles) {
          if (articles.isEmpty) {
            return EmptyState(
              icon: Icons.article_outlined,
              title: 'Không tìm thấy bài viết',
              subtitle: 'Kéo xuống để tải lại',
              actionLabel: 'Tải lại',
              onAction: () => ref.invalidate(provider),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final contentService = ref.read(contentServiceProvider);
              try {
                if (categoryUrl != null) {
                  await contentService.refreshUrl(categoryUrl!, category);
                } else {
                  await contentService.refreshCategory(category);
                }
                ref.invalidate(provider);
              } catch (e) {
                if (context.mounted) {
                  showErrorToast(context, 'Tải lại thất bại: $e');
                }
              }
            },
            child: ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return ArticleTile(
                  article: articles[index],
                  onTap: () {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .playFromIndex(articles, index);
                  },
                );
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
                label: const Text('Phát tất cả'),
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
