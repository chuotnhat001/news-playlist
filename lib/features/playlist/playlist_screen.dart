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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _formatCategory(category),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
          child: articlesAsync.when(
            loading: () => _buildLoadingState(),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Không tải được bài viết',
              subtitle: 'Vui lòng kiểm tra kết nối mạng và thử lại',
              actionLabel: 'Thử lại',
              onAction: () => ref.invalidate(provider),
            ),
            data: (articles) {
              if (articles.isEmpty) {
                return EmptyState(
                  icon: Icons.music_off_outlined,
                  title: 'Không tìm thấy audio',
                  subtitle: 'Danh mục này chưa có bài viết nào có audio.\nThử danh mục khác hoặc quay lại sau.',
                  actionLabel: 'Thử lại',
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
                            .playFromIndex(articles, index, category: category, categoryUrl: categoryUrl);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: articlesAsync.whenOrNull(
        data: (articles) => articles.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  AnalyticsService().logPlayAll(category, articles.length);
                  ref
                      .read(audioPlayerProvider.notifier)
                      .setPlaylist(articles, category: category, categoryUrl: categoryUrl);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Phát tất cả'),
              )
            : null,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Semantics(
        label: 'Đang tìm bài viết có audio',
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00DCFF)),
            const SizedBox(height: 24),
            Text(
              'Đang tìm bài viết có audio...',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Quá trình này có thể mất 10-30 giây',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCategory(String category) {
    return category.split('-').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
