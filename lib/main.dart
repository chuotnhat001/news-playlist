import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/app_shell.dart';
import 'package:news_playlist/features/home/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: NewsPlaylistApp()));
}

class NewsPlaylistApp extends StatelessWidget {
  const NewsPlaylistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Playlist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AppShell(child: HomeScreen()),
    );
  }
}
