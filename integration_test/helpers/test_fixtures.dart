import 'package:news_playlist/models/article.dart';
import 'package:news_playlist/models/category_config.dart';

class TestFixtures {
  static CategoryConfig get techCategory => const CategoryConfig(
        id: 'soha_cong-nghe',
        name: 'Công Nghệ',
        url: 'https://soha.vn/cong-nghe.htm',
        source: 'soha',
      );

  static CategoryConfig get businessCategory => const CategoryConfig(
        id: 'soha_kinh-doanh',
        name: 'Kinh Doanh',
        url: 'https://soha.vn/kinh-doanh.htm',
        source: 'soha',
      );

  static List<Article> get techArticles => List.generate(
        5,
        (i) => Article(
          id: 'tech_$i',
          title: 'Bài viết công nghệ ${i + 1}',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/2024/01/0$i/test-audio-$i.m4a',
          articleUrl: 'https://soha.vn/bai-viet-tech-$i.htm',
          category: 'soha_cong-nghe',
          publishedAt: DateTime.now().subtract(Duration(hours: i)),
          cachedAt: DateTime.now(),
        ),
      );

  static List<Article> get businessArticles => List.generate(
        3,
        (i) => Article(
          id: 'biz_$i',
          title: 'Bài viết kinh doanh ${i + 1}',
          source: 'soha',
          audioUrl: 'https://tts.mediacdn.vn/2024/01/0$i/test-biz-$i.m4a',
          articleUrl: 'https://soha.vn/bai-viet-biz-$i.htm',
          category: 'soha_kinh-doanh',
          publishedAt: DateTime.now().subtract(Duration(hours: i)),
          cachedAt: DateTime.now(),
        ),
      );
}
