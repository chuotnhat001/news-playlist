import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/app_shell.dart';
import 'package:news_playlist/features/home/home_screen.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';
import 'package:news_playlist/providers/content_provider.dart';
import 'package:news_playlist/services/audio_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioService = JustAudioNewsService();
  final audioHandler = await initAudioHandler(audioService);

  runApp(
    ProviderScope(
      overrides: [
        newsAudioServiceProvider.overrideWithValue(audioService),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const NewsPlaylistApp(),
    ),
  );
}

class NewsPlaylistApp extends ConsumerStatefulWidget {
  const NewsPlaylistApp({super.key});

  @override
  ConsumerState<NewsPlaylistApp> createState() => _NewsPlaylistAppState();
}

class _NewsPlaylistAppState extends ConsumerState<NewsPlaylistApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final contentService = ref.read(contentServiceProvider);
    await contentService.init();
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Playlist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return AppShell(child: child ?? const SizedBox.shrink());
      },
      home: _initialized
          ? const HomeScreen()
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
