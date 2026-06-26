import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:news_playlist/services/cache_service.dart';

import '../helpers/fake_audio_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';
import '../helpers/test_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Resume playback flow', () {
    late CacheService cache;

    setUp(() async {
      cache = CacheService();
      await cache.init();
      await cache.clearAll();
      await cache.clearPlaybackState();
    });

    testWidgets('resume card appears when saved state exists', (tester) async {
      await cache.insertCategory(TestFixtures.techCategory);
      await cache.insertArticles(TestFixtures.techArticles);
      await cache.savePlaybackState(
        category: 'soha_cong-nghe',
        articleIndex: 2,
        articleId: 'tech_2',
        positionMs: 45000,
      );

      final app = await createTestApp(cacheService: cache, seedData: false);
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      expect(find.text('Tiếp tục nghe'), findsOneWidget);
    });

    testWidgets('no resume card when no saved state', (tester) async {
      await cache.insertCategory(TestFixtures.techCategory);

      final app = await createTestApp(cacheService: cache, seedData: false);
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      expect(find.text('Tiếp tục nghe'), findsNothing);
    });

    testWidgets('tap resume card starts playback at saved position',
        (tester) async {
      final fakeAudio = FakeNewsAudioService();
      await cache.insertCategory(TestFixtures.techCategory);
      await cache.insertArticles(TestFixtures.techArticles);
      await cache.savePlaybackState(
        category: 'soha_cong-nghe',
        categoryUrl: 'https://soha.vn/cong-nghe.htm',
        articleIndex: 2,
        articleId: 'tech_2',
        positionMs: 45000,
      );

      final app = await createTestApp(
        audioService: fakeAudio,
        cacheService: cache,
        seedData: false,
      );
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.text('Tiếp tục nghe'));
      await tester.pumpAndSettle();

      expect(fakeAudio.playedUrls, isNotEmpty);
      expect(fakeAudio.playedUrls.first, contains('test-audio-2'));
    });
  });
}
