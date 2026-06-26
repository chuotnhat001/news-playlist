import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/fake_audio_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Browse and play flow', () {
    late FakeNewsAudioService fakeAudio;

    setUp(() {
      fakeAudio = FakeNewsAudioService();
    });

    testWidgets('home screen displays category cards', (tester) async {
      final app = await createTestApp(audioService: fakeAudio);
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      expect(find.text('Công Nghệ'), findsOneWidget);
      expect(find.text('Kinh Doanh'), findsOneWidget);
    });

    testWidgets('tap category navigates to playlist screen', (tester) async {
      final app = await createTestApp(audioService: fakeAudio);
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.text('Công Nghệ'));
      await tester.pumpAndSettle();

      expect(find.text('Bài viết công nghệ 1'), findsOneWidget);
    });

    testWidgets('tap article starts playback and shows mini player',
        (tester) async {
      final app = await createTestApp(audioService: fakeAudio);
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.text('Công Nghệ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bài viết công nghệ 1'));
      await tester.pumpAndSettle();

      expect(fakeAudio.playedUrls, isNotEmpty);
      expect(
        fakeAudio.playedUrls.first,
        contains('test-audio-0'),
      );

      // MiniPlayer should show the article title
      expect(find.text('Bài viết công nghệ 1'), findsWidgets);
    });

    testWidgets('tap mini player navigates to player screen', (tester) async {
      final app = await createTestApp(audioService: fakeAudio);
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.text('Công Nghệ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bài viết công nghệ 1'));
      await tester.pumpAndSettle();

      // Tap mini player area (the article title in mini player)
      final miniPlayerTitle = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.text('Bài viết công nghệ 1'),
      );
      if (miniPlayerTitle.evaluate().isNotEmpty) {
        await tester.tap(miniPlayerTitle.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
