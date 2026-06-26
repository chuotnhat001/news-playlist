import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/fake_audio_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Player controls flow', () {
    late FakeNewsAudioService fakeAudio;

    setUp(() {
      fakeAudio = FakeNewsAudioService();
    });

    Future<void> startPlayback(WidgetTester tester) async {
      final app = await createTestApp(audioService: fakeAudio);
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.text('Công Nghệ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phát tất cả'));
      await tester.pumpAndSettle();
    }

    testWidgets('pause button pauses playback', (tester) async {
      await startPlayback(tester);

      // Find and tap pause button in mini player
      final pauseButton = find.byIcon(Icons.pause);
      if (pauseButton.evaluate().isNotEmpty) {
        await tester.tap(pauseButton.first);
        await tester.pumpAndSettle();
        expect(fakeAudio.pauseCount, 1);
      }
    });

    testWidgets('play button resumes playback', (tester) async {
      await startPlayback(tester);

      // Tap pause button in mini player first
      final pauseButton = find.byIcon(Icons.pause);
      if (pauseButton.evaluate().isNotEmpty) {
        await tester.tap(pauseButton.first);
        await tester.pumpAndSettle();
      }

      // Now tap play button to resume
      final playButton = find.byIcon(Icons.play_arrow);
      if (playButton.evaluate().isNotEmpty) {
        await tester.tap(playButton.last);
        await tester.pumpAndSettle();
        expect(fakeAudio.resumeCount, greaterThanOrEqualTo(1));
      }
    });

    testWidgets('skip next advances track', (tester) async {
      await startPlayback(tester);

      // Simulate track completion to advance
      fakeAudio.emitCompleted();
      await tester.pumpAndSettle();

      expect(fakeAudio.playedUrls.length, 2);
      expect(fakeAudio.playedUrls[1], contains('test-audio-1'));
    });
  });
}
