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

  runApp(ProviderScope(
    overrides: [
      newsAudioServiceProvider.overrideWithValue(audioService),
      audioHandlerProvider.overrideWithValue(audioHandler),
    ],
    child: const NewsPlaylistApp(),
  ));
}

class NewsPlaylistApp extends ConsumerStatefulWidget {
  const NewsPlaylistApp({super.key});

  @override
  ConsumerState<NewsPlaylistApp> createState() => _NewsPlaylistAppState();
}

class _NewsPlaylistAppState extends ConsumerState<NewsPlaylistApp>
    with WidgetsBindingObserver {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(audioPlayerProvider.notifier).saveState();
    }
  }

  Future<void> _initServices() async {
    try {
      final contentService = ref.read(contentServiceProvider);
      await contentService.init();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      debugPrint('[Init] Error: $e');
      if (mounted) setState(() => _error = e.toString());
    }
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
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Init error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() { _error = null; });
                  _initServices();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const HomeScreen();
  }
}
