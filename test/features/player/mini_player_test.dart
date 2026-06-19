import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/player/mini_player.dart';
import 'package:news_playlist/providers/audio_player_provider.dart';
import 'package:news_playlist/models/article.dart';

void main() {
  final testArticle = Article(
    id: 'test-1',
    title: 'Test Article',
    source: 'dantri',
    audioUrl: 'https://example.com/audio.mp3',
    articleUrl: 'https://example.com/article',
    category: 'cong-nghe',
    publishedAt: DateTime(2026, 6, 20),
    cachedAt: DateTime(2026, 6, 20),
  );

  testWidgets('MiniPlayer is hidden when no audio playing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: MiniPlayer())),
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.text('Test Article'), findsNothing);
  });

  testWidgets('MiniPlayer shows track info when playing', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(audioPlayerProvider.notifier)
        .setPlaylist([testArticle]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MiniPlayer())),
      ),
    );

    await tester.pump();
    expect(find.text('Test Article'), findsOneWidget);
    expect(find.text('dantri'), findsOneWidget);
  });
}
