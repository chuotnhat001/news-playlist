import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/app_shell.dart';
import 'package:news_playlist/features/home/home_screen.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';
import 'package:news_playlist/providers/content_provider.dart';
import 'package:news_playlist/services/cache_service.dart';
import 'package:news_playlist/services/content_service.dart';

import 'fake_audio_service.dart';
import 'test_fixtures.dart';

int _dbCounter = 0;

Future<Widget> createTestApp({
  FakeNewsAudioService? audioService,
  CacheService? cacheService,
  bool seedData = true,
}) async {
  final fakeAudio = audioService ?? FakeNewsAudioService();
  final cache = cacheService ?? CacheService();

  if (!cache.isReady) {
    await cache.init();
  }

  if (seedData) {
    await cache.insertCategory(TestFixtures.techCategory);
    await cache.insertCategory(TestFixtures.businessCategory);
    await cache.insertArticles(TestFixtures.techArticles);
    await cache.insertArticles(TestFixtures.businessArticles);
  }

  final content = ContentService(
    cacheService: cache,
    crawlerServices: {},
  );

  return ProviderScope(
    overrides: [
      newsAudioServiceProvider.overrideWithValue(fakeAudio),
      audioHandlerProvider.overrideWithValue(null),
      cacheServiceProvider.overrideWithValue(cache),
      contentServiceProvider.overrideWithValue(content),
    ],
    child: const TestNewsPlaylistApp(),
  );
}

class TestNewsPlaylistApp extends ConsumerStatefulWidget {
  const TestNewsPlaylistApp({super.key});

  @override
  ConsumerState<TestNewsPlaylistApp> createState() =>
      _TestNewsPlaylistAppState();
}

class _TestNewsPlaylistAppState extends ConsumerState<TestNewsPlaylistApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final contentService = ref.read(contentServiceProvider);
    await contentService.init();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Playlist Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return AppShell(child: child ?? const SizedBox.shrink());
      },
      home: _initialized
          ? const HomeScreen()
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
