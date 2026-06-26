import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/fake_audio_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Play all flow', () {
    late FakeNewsAudioService fakeAudio;

    setUp(() {
      fakeAudio = FakeNewsAudioService();
    });

    testWidgets('FAB phát tất cả starts playlist from first article',
        (tester) async {
      final app = await createTestApp(audioService: fakeAudio);
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.text('Công Nghệ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phát tất cả'));
      await tester.pumpAndSettle();

      expect(fakeAudio.playedUrls.first, contains('test-audio-0'));
    });

    testWidgets('track completion advances to next article', (tester) async {
      final app = await createTestApp(audioService: fakeAudio);
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.text('Công Nghệ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phát tất cả'));
      await tester.pumpAndSettle();

      // Simulate track completion
      fakeAudio.emitCompleted();
      await tester.pumpAndSettle();

      expect(fakeAudio.playedUrls.length, 2);
      expect(fakeAudio.playedUrls[1], contains('test-audio-1'));
    });
  });
}
