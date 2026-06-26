import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/home/widgets/category_card.dart';
import 'package:news_playlist/features/home/widgets/resume_card.dart';
import 'package:news_playlist/features/playlist/playlist_screen.dart';
import 'package:news_playlist/features/settings/settings_screen.dart';
import 'package:news_playlist/models/category_config.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';
import 'package:news_playlist/providers/content_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<CategoryConfig> _customCategories = [];
  final Map<String, int?> _articleCounts = {};
  final Map<String, bool> _loadingStates = {};
  bool _loading = true;
  Map<String, dynamic>? _savedPlayback;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPlaybackState();
  }

  Future<void> _loadPlaybackState() async {
    final cacheService = ref.read(cacheServiceProvider);
    final saved = await cacheService.getPlaybackState();
    if (mounted) {
      setState(() => _savedPlayback = saved);
    }
  }

  Future<void> _resumePlayback() async {
    if (_savedPlayback == null) return;
    final playback = _savedPlayback!;
    setState(() => _savedPlayback = null); // Prevent double-tap

    final category = playback['category'] as String;
    final categoryUrl = playback['category_url'] as String?;
    final articleIndex = playback['article_index'] as int;
    final articleId = playback['article_id'] as String?;
    final positionMs = playback['position_ms'] as int;

    final contentService = ref.read(contentServiceProvider);
    final articles = categoryUrl != null
        ? await contentService.getArticlesFromUrl(categoryUrl, category)
        : await contentService.getArticles(category);

    if (!mounted) return;

    if (articles.isEmpty) {
      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.clearPlaybackState();
      return;
    }

    // Find article by ID first, fallback to index
    int resolvedIndex;
    if (articleId != null) {
      final idIndex = articles.indexWhere((a) => a.id == articleId);
      resolvedIndex = idIndex >= 0 ? idIndex : articleIndex;
    } else {
      resolvedIndex = articleIndex;
    }

    if (resolvedIndex >= articles.length) {
      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.clearPlaybackState();
      return;
    }

    final notifier = ref.read(audioPlayerProvider.notifier);
    await notifier.playFromIndex(articles, resolvedIndex, category: category, categoryUrl: categoryUrl);
    if (!mounted) return;
    await notifier.seekWhenReady(Duration(milliseconds: positionMs));
  }

  Future<void> _loadCategories() async {
    final contentService = ref.read(contentServiceProvider);
    final categories = await contentService.getCustomCategories();
    if (mounted) {
      setState(() {
        _customCategories = categories;
        _loading = false;
      });
      _loadArticleCounts(categories);
    }
  }

  Future<void> _loadArticleCounts(List<CategoryConfig> categories) async {
    final contentService = ref.read(contentServiceProvider);
    final counts = await Future.wait(
      categories.map((cat) => contentService.getArticleCount(cat.id)),
    );
    if (mounted) {
      setState(() {
        for (var i = 0; i < categories.length; i++) {
          _articleCounts[categories[i].id] = counts[i];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'News Playlist',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadCategories();
            },
          ),
        ],
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
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent))
              : _customCategories.isEmpty
                  ? _buildEmptyState()
                  : _buildCategoryGrid(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rss_feed, size: 64, color: Colors.cyanAccent),
            const SizedBox(height: 16),
            const Text(
              'Chưa có danh mục nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm URL danh mục từ soha.vn\nđể bắt đầu nghe tin tức',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                _loadCategories();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: const Color(0xFF0D0D2B),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Thêm danh mục'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(CategoryConfig cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa danh mục'),
        content: Text('Bạn có chắc muốn xóa "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final contentService = ref.read(contentServiceProvider);
      await contentService.removeCategory(cat.id);
      _loadCategories();
    }
  }

  Future<void> _reloadCategory(CategoryConfig cat) async {
    setState(() => _loadingStates[cat.id] = true);
    final contentService = ref.read(contentServiceProvider);
    try {
      await contentService.refreshUrl(cat.url, cat.id);
      if (mounted) {
        final count = await contentService.getArticleCount(cat.id);
        setState(() => _articleCounts[cat.id] = count);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingStates[cat.id] = false);
      }
    }
  }

  Widget _buildCategoryGrid() {
    final hasResume = _savedPlayback != null;
    final itemCount = _customCategories.length + (hasResume ? 1 : 0);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (hasResume && index == 0) {
          return ResumeCard(
            category: _savedPlayback!['category'] as String,
            articleIndex: _savedPlayback!['article_index'] as int,
            onTap: _resumePlayback,
          );
        }
        final catIndex = hasResume ? index - 1 : index;
        final cat = _customCategories[catIndex];
        return CategoryCard(
          category: cat.name,
          articleCount: _articleCounts[cat.id],
          isLoading: _loadingStates[cat.id] == true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistScreen(
                  category: cat.id,
                  categoryUrl: cat.url,
                ),
              ),
            );
          },
          onReload: () => _reloadCategory(cat),
          onDelete: () => _deleteCategory(cat),
        );
      },
    );
  }
}
