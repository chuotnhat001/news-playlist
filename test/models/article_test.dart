import 'package:flutter_test/flutter_test.dart';
import 'package:news_playlist/models/article.dart';

void main() {
  final testArticle = Article(
    id: 'dantri-123',
    title: 'Test Article Title',
    source: 'dantri',
    audioUrl: 'https://cdn.dantri.com/audio/123.mp3',
    articleUrl: 'https://dantri.com.vn/article-123.htm',
    category: 'cong-nghe',
    publishedAt: DateTime(2026, 6, 20, 10, 30),
    cachedAt: DateTime(2026, 6, 20, 11, 0),
  );

  group('Article toMap/fromMap', () {
    test('toMap produces correct map with DateTime as milliseconds', () {
      final map = testArticle.toMap();

      expect(map['id'], 'dantri-123');
      expect(map['title'], 'Test Article Title');
      expect(map['source'], 'dantri');
      expect(map['audioUrl'], 'https://cdn.dantri.com/audio/123.mp3');
      expect(map['articleUrl'], 'https://dantri.com.vn/article-123.htm');
      expect(map['category'], 'cong-nghe');
      expect(map['publishedAt'], isA<int>());
      expect(map['cachedAt'], isA<int>());
    });

    test('fromMap reconstructs Article correctly', () {
      final map = testArticle.toMap();
      final reconstructed = Article.fromMap(map);

      expect(reconstructed.id, testArticle.id);
      expect(reconstructed.title, testArticle.title);
      expect(reconstructed.source, testArticle.source);
      expect(reconstructed.audioUrl, testArticle.audioUrl);
      expect(reconstructed.articleUrl, testArticle.articleUrl);
      expect(reconstructed.category, testArticle.category);
      expect(reconstructed.publishedAt, testArticle.publishedAt);
      expect(reconstructed.cachedAt, testArticle.cachedAt);
    });

    test('roundtrip toMap -> fromMap produces equal Article', () {
      final roundtripped = Article.fromMap(testArticle.toMap());
      expect(roundtripped, equals(testArticle));
    });
  });

  group('Article copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final copied = testArticle.copyWith(title: 'New Title');

      expect(copied.title, 'New Title');
      expect(copied.id, testArticle.id);
      expect(copied.source, testArticle.source);
      expect(copied.audioUrl, testArticle.audioUrl);
      expect(copied.category, testArticle.category);
    });

    test('copyWith changes all specified fields', () {
      final copied = testArticle.copyWith(
        title: 'New Title',
        source: 'soha',
        category: 'kinh-doanh',
      );

      expect(copied.title, 'New Title');
      expect(copied.source, 'soha');
      expect(copied.category, 'kinh-doanh');
    });
  });

  group('Article equality', () {
    test('two articles with same id are equal', () {
      final other = testArticle.copyWith(title: 'Different Title');
      expect(testArticle, equals(other));
    });

    test('two articles with different id are not equal', () {
      final other = testArticle.copyWith(id: 'different-id');
      expect(testArticle, isNot(equals(other)));
    });

    test('hashCode is consistent with equality', () {
      final other = testArticle.copyWith(title: 'Different Title');
      expect(testArticle.hashCode, equals(other.hashCode));
    });
  });
}
